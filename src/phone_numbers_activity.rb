require 'ruboto/widget'
require 'ruboto/util/stack'

with_large_stack(:size => 256) {
  require 'ostruct'
  require 'json/pure'
}

require 'server'

import "android.content.Intent"
import "android.net.Uri"

ruboto_import_widgets :LinearLayout, :Button, :EditText, :TextView


class PhoneNumbersActivity
  def on_create(bundle)
    super
    set_title 'Phone Numbers'

    bundle = getIntent().getExtras()
    @box = bundle.getString('Box')
    @phone_numbers = JSON.load bundle.getString('Body')
    @phone_numbers = Array.new unless @phone_numbers.class == Array

    render
  rescue
    puts "Exception creating activity: #{$!}"
    puts $!.backtrace.join("\n")
  end


  def on_activity_result(request, result, i)
    super(request, result, i)
    begin
      phone_number = {
        'name' => i.getStringExtra('Name'),
        'number'   => i.getStringExtra('Number')
      }
      Server.new.post phone_number, "/board/#{@box}/new"
    rescue
      @error = "Cannot save new content"
    end
    @phone_numbers << phone_number if phone_number
    render
  end

private

  def call_number(n)
    intent = Intent.new(Intent::ACTION_CALL)
    intent.setData(Uri.parse("tel:#{n}"))
    startActivity(intent)
  end

  def go_back
    i = Intent.new
    i.putExtra('Box', @box )
    i.putExtra('Body', JSON.dump( @phone_numbers ))

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

      @phone_numbers.each do |phone_number|
        button :text => phone_number['name'] || phone_number['number'],
          :on_click_listener => proc{call_number(phone_number['number'])},
          :on_long_click_listener => proc{edit(phone_number)}
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
    bundle.put_string('ClassName', 'NewPhoneNumberActivity')
    i.putExtra('Ruboto Config', bundle)
    startActivityForResult(i, 1)
  end

  def edit(phone_number)
    i = Intent.new
    i.setClassName($package_name, 'org.ruboto.RubotoActivity')
    bundle = android.os.Bundle.new
    bundle.put_string('ClassName', 'NewPhoneNumberActivity')
    i.putExtra('Ruboto Config', bundle)
    i.putExtra('Name',  phone_number['name'])
    i.putExtra('Number',  phone_number['number'])
    startActivityForResult(i, 1)
  end

end


class NewPhoneNumberActivity
  def on_create(bundle)
    super
    set_title 'New Phone Number'
    bundle = getIntent().getExtras()

    self.content_view = linear_layout :orientation => :vertical do

      text_view :text => 'Name'
      name = edit_text :single_line => true,
        :text => bundle.getString('name')||''

      text_view :text => 'Number'
      number = edit_text :single_line => true,
        :text => bundle.getString('number')||''

      button :text => 'Submit',
        :on_click_listener => proc{submit(name.getText, number.getText)}
    end
  end

  def submit(name, number)
    i = Intent.new
    i.putExtra('Name',    name.to_s )
    i.putExtra('Number',  number.to_s )
    setResult(PhoneNumbersActivity::RESULT_OK, i)
    finish
  end

end
