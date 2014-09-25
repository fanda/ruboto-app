require 'ruboto/widget'
#require 'ruboto/util/toast'
require 'ruboto/util/stack'

with_large_stack(:size => 256) {
  require 'ostruct'
  require 'json/pure'
}

require 'server'

import "android.content.Intent"
import "android.net.Uri"

ruboto_import_widgets :LinearLayout, :Button, :EditText, :TextView


class LinksActivity
  def on_create(bundle)
    super
    set_title 'Links'

    bundle = getIntent().getExtras()
    @box = bundle.getString('Box')
    @links = JSON.load bundle.getString('Body')
    @links = Array.new unless @links.class == Array

    render
  rescue
    puts "Exception creating activity: #{$!}"
    puts $!.backtrace.join("\n")
  end


  def on_activity_result(request, result, i)
    super(request, result, i)
    begin
      link = {
        'title' => i.getStringExtra('Title'),
        'url'   => i.getStringExtra('Url')
      }
      Server.new.post link, "/board/#{@box}/new"
    rescue
      @error = "Cannot save new content"
    end
    @links << link if link
    render
  end

private

  def show_url(href)
    intent = Intent.new Intent::ACTION_VIEW
    intent.setData Uri.parse(href)
    startActivity intent
    #finish # no, we do not want to finish
  end

  def go_back
    i = Intent.new
    i.putExtra('Box', @box )
    i.putExtra('Body', JSON.dump( @links ))

    setResult(RESULT_OK, i)
    finish
  end

  def render
    self.content_view = linear_layout :orientation => :vertical do
      linear_layout :orientation => :horizontal do
        button :text => 'Back',
          :on_click_listener => proc{go_back}
        button :text => 'New',
          :on_click_listener => proc{new}
      end

      @links.each do |link|
        button :text => link['title'] || link['url'],
          :on_click_listener => proc{show_url(link['url'])},
          :on_long_click_listener => proc{edit(link)}
      end

      if @error
        text_view :text => @error
      end

    end
  end

  def new
    i = Intent.new
    i.setClassName($package_name, 'org.ruboto.RubotoActivity')
    bundle = android.os.Bundle.new
    bundle.put_string('ClassName', 'NewLinkActivity')
    i.putExtra('Ruboto Config', bundle)
    startActivityForResult(i, 1)
  end

  def edit(link)
    i = Intent.new
    i.setClassName($package_name, 'org.ruboto.RubotoActivity')
    bundle = android.os.Bundle.new
    bundle.put_string('ClassName', 'NewLinkActivity')
    i.putExtra('Ruboto Config', bundle)
    i.putExtra('Title',  link['title'])
    i.putExtra('Url',  link['url'])
    startActivityForResult(i, 1)
  end

end


class NewLinkActivity
  def on_create(bundle)
    super
    set_title 'New Link'
    bundle = getIntent().getExtras()

    self.content_view = linear_layout :orientation => :vertical do

      text_view :text => 'Title'
      title = edit_text :single_line => true,
        :text => bundle.getString('Title')||''

      text_view :text => 'Url'
      url = edit_text :single_line => true,
        :text => bundle.getString('Url')||'http://'

      button :text => 'Submit',
        :on_click_listener => proc{submit(title.getText, url.getText)}
    end
  end

  def submit(title, url)
    i = Intent.new
    i.putExtra('Title', title.to_s )
    i.putExtra('Url',   url.to_s )
    setResult(LinksActivity::RESULT_OK, i)
    finish
  end

end
