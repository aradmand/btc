require 'mechanize'
require 'pry'

# a = Mechanize.new { |agent|
#   agent.user_agent_alias = 'Mac Safari'
# }

# a.get('http://google.com/') do |page|

#   search_result = page.form_with(:name => 'f') do |search|
#     search.q = 'Hello world'
#   end.submit

#   search_result.links.each do |link|
#     puts link.text
#   end
# end



a = Mechanize.new { |agent|
  agent.user_agent_alias = 'Mac Safari'
}

a.get('https://www.circle.com') do |page|
  login_page = a.click(page.link_with(:text => /Sign In/))

  my_page = login_page.form_with(:action => '/signin/') do |f|
    f.form_loginname  = ARGV[0]
    f.form_pw         = ARGV[1]
  end.click_button


  # search_result = page.form_with(:name => 'f') do |search|
  #   search.q = 'Hello world'
  # end.submit

  # search_result.links.each do |link|
  #   puts link.text
  # end
end
