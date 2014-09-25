require 'ruboto/widget'
#require 'ruboto/util/toast'
require 'ruboto/util/stack'

with_large_stack(:size => 256) {
  require 'ostruct'
  require 'json/pure'
}

require 'server'

import "android.content.Intent"

ruboto_import_widgets :LinearLayout, :Button, :EditText, :TextView

class MtActivity

  def on_create(bundle)
    #@board_id = "5159ed17d2d26bb107000000" # old
    @board_id = '51560c68f605bf080e000000'

    @board = Server.json.my_board @board_id

    show_me
  end

  def on_activity_result(request, result, i)
    super(request, result, i)

    box = nil
    with_large_stack(:size => 256) {
      box = JSON.load i.getStringExtra('Body')
    }
    @board['boxes'][i.getStringExtra('Box')]['content'] = box
    show_me
  end


private

  LINKS_BOX = 'links'

  PHONE_NUMBERS_BOX = 'phone_numbers'


  def show_me
    setTitle @board["name"].empty? ? 'MT4EXMEM.ORG' : @board["name"]
    self.content_view = linear_layout :orientation => :vertical do
      text_view :text => 'RUBY'
      text_view :text => @board.inspect

      button :text => 'Links',
        :on_click_listener => proc{show_links}

      button :text => 'PhoneNumbers',
        :on_click_listener => proc{show_phone_numbers}

    end
  end

  def show_links
    bundle = android.os.Bundle.new
    bundle.put_string('ClassName', 'LinksActivity')

    i = Intent.new
    i.setClassName($package_name, 'org.ruboto.RubotoActivity')
    i.putExtra('Ruboto Config', bundle)
    i.putExtra('Body', JSON.dump( box_content(LINKS_BOX) ))
    i.putExtra('Box', LINKS_BOX )

    startActivityForResult(i, 1) # 1 is request code
  end

  def show_phone_numbers
    bundle = android.os.Bundle.new ## how to access any non-imported class
    bundle.put_string('ClassName', 'PhoneNumbersActivity')

    i = Intent.new ## how to access importet class
    i.setClassName($package_name, 'org.ruboto.RubotoActivity')
    i.putExtra('Ruboto Config', bundle)
    i.putExtra('Body', JSON.dump( box_content(PHONE_NUMBERS_BOX) ))
    i.putExtra('Box', PHONE_NUMBERS_BOX )

    startActivityForResult(i, 1) # 1 is request code
  end

  def box_content(id)
    return @board['boxes'][id] ? @board['boxes'][id]['content'] : nil
  end

end
