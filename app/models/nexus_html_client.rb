class NexusHtmlClient
  include HTTParty
  base_uri NEXUS_DOMAIN

  def initialize(u,p)
    @username = u
    @password = p
    @php_session_id = nil
  end
  
  def login
    query = {
       "a" => 'home',
       "sa" => 'first'
    }
    body = {
       "UserName" => @username,
       "PassWord" => @password,
       "forever" => 'on',
       "Action" => 'Login'
       }
    options = {:quary => query, :body => body}
    cookies = {"USE_COOKIES" => "1"}
    self.class.cookies(cookies)
    response = self.class.post(INDEX_PATH, options)
    set_cookies = response.headers["set-cookie"].split(";") if response.headers["set-cookie"]
    @php_session_id = set_cookies[0].split("=")[1].strip unless set_cookies.empty?
    self
  end

  def get(a, sa=nil,id=nil,sys=nil)
    login unless @php_session_id
    url = "#{INDEX_PATH}?a=#{a}"
    url = url + "&sa=#{sa}" if sa
    url = url + "&id=#{id}" if id
    url = url + "&sys=#{sys}" if sys
    fetch_page(url)
  end

  def get_turn(id)
    login unless @php_session_id
    url = "#{INDEX_PATH}?a=turns&sa=list&la=find&id=#{id}"
    code, doc = fetch_page(url)
    return code, doc unless code == 200
    doc.xpath('//td[@class="turns_tab_off"]').each do |n|
      # LOG.info "N = #{n.content}"
      anchor = n.xpath('.//a').first
      if anchor.content.include?("(#{id})")
        onclick = anchor['onclick']
        ni = onclick.index('/')
        nj = onclick.index('"',ni)
        url = onclick[ni..(nj-1)]
        code, doc = fetch_page(url)
        doc = NexusTurn.new(id,doc) if code == 200
        return code, doc
      end
    end
    nil
  end

  def get_jump_map(periphery_id)
    login unless @php_session_id
    url = "#{INDEX_PATH}?a=game&sa=jump&id=#{periphery_id}"
    code, doc = fetch_page(url)
    return code, doc unless code == 200
    doc.xpath('//div[@class="jump_map_system"]').each do |s|
      ss = parse_star_system(s.content)
      ss.periphery_id = periphery_id
      LOG.info "S = #{s}" if ss.save
    end
    doc.xpath('//div[@class="jump_map_link"]').each do |jl|
      jlp = jl['title'].strip.split('<->')
      ss_a = parse_star_system(jlp[0])
      ss_a.save
      jlj = jlp[1].split('[')
      ss_b = parse_star_system(jlj[0])
      ss_b.save
      jumps = jlj[1].gsub('jumps','').gsub('jump','').gsub(']','').to_i
      jl = JumpLink.link_systems!(ss_a, ss_b, jumps)
      LOG.info "JL = #{jl}"
    end
    nil
  end

  def get_position_turns
#     ?a=notes&sa=get_list 

# gets the notifications - you need you want it through the other ?a=xml method ? 

# type=1 are types 
# type=2 are new positions 

    login unless @php_session_id
    url = "#{INDEX_PATH}?a=notes&sa=get_list"
    cookies = {"USE_COOKIES" => "1", "PHPSESSID" => @php_session_id}
    self.class.cookies(cookies)
    response = self.class.get(url)
    unless response.code == 200
      LOG.info "Nexus: Error #{response.code}"
      return response.code, nil
    end
    response['data']['id_lists']['pos']['pos']
  end

  private
  def parse_star_system(s)
    sp = s.strip.split('(')
    name = sp[0].strip
    id = sp[1].gsub(')','').strip
    ss = StarSystem.find_by_id(id)
    unless ss
      ss = StarSystem.new(name: name)
      ss.id = id
    end
    ss
  end

  def fetch_page(url)
    puts "Fetching #{url}"
    cookies = {"USE_COOKIES" => "1", "PHPSESSID" => @php_session_id}
    self.class.cookies(cookies)
    response = self.class.get(url)
    unless response.code == 200
      LOG.info "Nexus: Error #{response.code}"
      return response.code, nil
    end
    #puts response
    doc = Nokogiri::HTML(response)
    return response.code, doc
  end
end
