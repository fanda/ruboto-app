with_large_stack(:size => 256) {
  require 'ostruct'
  require 'net/http'
  require 'json/pure'
}

class Server
  include Net

  @@bid = '51560c68f605bf080e000000' # default, probably not valid


  def self.json
    Server.new
  end

  def initialize
    java.lang.System.setProperty("java.net.preferIPv6Addresses", "false");
    @srv = HTTP.new("mt.exmem.org", 80)
  end

  def bid!(id)
    @@bid = id
  end

  def my_board(id=nil)
    @@bid = id
    json = nil
    with_large_stack(:size => 256) {
      response = @srv.request HTTP::Get.new("/board.json?bid=#{id}")
      json = JSON.load response.body.to_s
    }
    json
  end

  def post(data, url)
    headers = {'Content-Type' => 'application/json'}
    req = HTTP::Post.new("#{url}?bid=#{@@bid}", headers)
    response = nil
    with_large_stack(:size => 256) {
      req.body = JSON.dump data
      response = @srv.request req
    }
    response.body
  end

end
