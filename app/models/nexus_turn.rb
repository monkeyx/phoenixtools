class NexusTurn
  attr_reader :id, :doc, :sections, :name, :affiliation #, :celestial_body, :star_system

  def initialize(id, doc)
    @id = id
    @doc = doc
    @sections = parse_sections(doc)
    @inventory = nil
    @raw_materials = nil
    @trade_items = nil
  end

  def personnel
    return @personnel if @personnel
    @personnel = read_personnel_section(@sections['Personnel Report'])
  end

  def inventory
    return @inventory if @inventory
    @inventory = read_item_section(@sections['Inventory Report'])
  end

  def raw_materials
    return @raw_materials if @raw_materials
    @raw_materials = read_item_section(@sections['Raw Material Report'])
  end

  def trade_items
    return @trade_items if @trade_items
    @trade_items = read_item_section(@sections['Trade Item Report'])
  end

  def item_groups
    return @item_groups if @item_groups
    @item_groups = {}
    self.sections.keys.each do |key|
      if key.index('Item Group')
        s = key.split(':')
        i = s[1].index('(')
        j = s[1].index(')')
        grp_name = s[1][0..(i-1)].strip
        grp_id = s[1][(i+1)..(j-1)].strip.to_i
        items = read_item_section(self.sections[key])
        @item_groups[grp_id] = {:name => grp_name, :items => items}
      end
    end
    @item_groups
  end

  def planetary_report
    return @planetary_report if @planetary_report
    @planetary_report = {}
    prs = self.sections['Planetary Report']
    if prs
      @planetary_report['Merchandising'] = {'Local' => {'Maximum' => prs[1][1], prs[0][2] => prs[1][2]},
        'Global' => {'Maximum' => prs[2][1], prs[0][2] => prs[2][2]}}
      @planetary_report['Trade'] = {
        'Trade Goods' => {'Max' => prs[4][1], 'Value/MU' => prs[4][2], 'Low' => prs[4][3], 'High' => prs[4][4]},
        'Drugs' => {'Max' => prs[5][1], 'Value/MU' => prs[5][2], 'Low' => prs[5][3], 'High' => prs[5][4]},
        'Lifeforms' => {'Max' => prs[6][1], 'Value/MU' => prs[6][2], 'Low' => prs[6][3], 'High' => prs[6][4]}
      }
    end
    @planetary_report
  end

  def resources
    return @resources if @resources
    @resources = []
    mining = {}
    mrs = self.sections['Mineral Report']
    if mrs
      (1..(mrs.size - 1)).each do |i|
        resource_id, resource = read_resource_row(mrs[i])
        mining[resource_id] = resource
      end
    end
    mrs = self.sections['Mining Report']
    if mrs
      (1..(mrs.size - 1)).each do |i|
        resource_id = mrs[i][3].to_i
        resource = mining[resource_id]
        if resource
          resource[:ore_mines] = mrs[i][0].to_i
          resource[:output] = mrs[i][4].to_f
        end
      end
    end
    mining.each do |key,resource|
      @resources << resource
    end
    resourcing = {}
    mrs = self.sections['Resource Report']
    if mrs
      (1..(mrs.size - 1)).each do |i|
        resource_id, resource = read_resource_row(mrs[i])
        resourcing[resource_id] = resource
      end
    end
    mrs = self.sections['Resource Extraction Report']
    if mrs
      (1..(mrs.size - 1)).each do |i|
        resource_id = mrs[i][2].to_i
        resource = resourcing[resource_id]
        resource[:resource_complexes] = mrs[i][0]
        resource[:change] = mrs[i][3]
        resource[:output] = mrs[i][4].to_f
      end
    end
    resourcing.each do |key,resource|
      @resources << resource
    end
    @resources
  end

  def mass_production
    return @mass_production if @mass_production
    @mass_production = []
    mps = self.sections['Production Report']
    if mps
      (1..(mps.size - 1)).each do |i|
        item = parse_item_str(mps[i][0])
        @mass_production << {:item => item, :factories => mps[i][1].to_i, :carry => mps[i][2].to_i, :status => mps[i][3]}
      end
    end
    @mass_production
  end

  def to_s
    "Turn #{id}"
  end

  private
  def read_resource_row(row)
    item = parse_item_str(row[0])
    resource_id = row[1].to_i
    resource_yield = row[2].to_f
    resource_drop = row[3].to_i
    resource_size = row[4] == 'Infinite' ? 'Infinite' : row[4].to_i
    return resource_id, {:item => item, :resource_id => resource_id, :resource_yield => resource_yield, :resource_drop => resource_drop, :resource_size => resource_size}
  end

  def parse_item_str(item_str)
    ni = item_str.index('(')
    nj = item_str.index(')')
    item_name = ni ? item_str[0..(ni-1)].strip : item_str
    item_id = item_str[(ni+1)..nj].strip.to_i if ni
    Item.fetch_if_new!(item_id, item_name) if item_id
  end

  def read_personnel_section(section,items_hash={})
    return items_hash unless section
    size = section.size
    (0..(size-1)).each do |i|
      unless section[i].nil? && section[i].size > 1
        qty = section[i][0].nil? ? nil : section[i][0].to_i
        item_str = section[i][1]
        if qty && item_str
          item = parse_item_str(item_str)
          count = items_hash[item]
          count = 0 unless count
          count += qty
          items_hash[item] = count
        end
      end
    end
    items_hash
  end

  def read_item_section(section,items_hash={})
    # LOG.info "SECTION SIZE = #{section.size}"
    return items_hash unless section
    size = section.size
    (1..(size-1)).each do |i|
      unless section[i].nil? && section[i].size > 1
        qty = section[i][0].nil? ? nil : section[i][0].to_i
        item_str = section[i][1]
        if qty && item_str
          item = parse_item_str(item_str)
          count = items_hash[item]
          count = 0 unless count
          count += qty
          items_hash[item] = count
        end
      end
    end
    items_hash
  end

  def parse_sections(doc)
    return nil unless doc
    table = {}
    self.doc.xpath('//td[@class="report_left"]').each do |n|
      section_heading = n.content
      # LOG.info "Section #{section_heading}"
      rows = []
      if section_heading == 'Personnel Report'
        rows = parse_table(n.parent.next_element.next_element.next_element)
        temp = parse_table(n.parent.next_element.next_element.next_element.next_element.next_element)
        if temp[0] && temp[0][0] == "SLAVES"
          rows = rows + parse_table(n.parent.next_element.next_element.next_element.next_element.next_element.next_element)
          rows = rows + parse_table(n.parent.next_element.next_element.next_element.next_element.next_element.next_element.next_element.next_element.next_element)
        elsif temp[0]
          rows = rows + parse_table(n.parent.next_element.next_element.next_element.next_element.next_element.next_element)
        end
      elsif section_heading == 'Mining Report' || section_heading == 'Resource Extraction Report'
        rows = parse_table(n.parent.next_element.next_element.next_element.next_element)
      elsif  section_heading == 'Planetary Report'
        rows = parse_table(n.parent.next_element.next_element.next_element.next_element.next_element.next_element) + parse_table(n.parent.next_element.next_element.next_element.next_element.next_element.next_element.next_element.next_element)
      elsif section_heading == 'Production Report'
        rows = parse_table(n.parent.next_element.next_element)
        rows = parse_table(n.parent.next_element.next_element.next_element.next_element) if rows.size > 0 && rows[0][0].downcase == "basic production"
      elsif section_heading == 'Command Report'
        rows = parse_table(n.parent.next_element.next_element)
        s = rows[0][1]
        s = s[0..(s.index('(')-1)].strip
        # LOG.info "NAME = #{s}"
        @name = s
        s = rows[0][3]
        s = s[(s.index('(')+1)..(s.index(')')-1)].strip.to_i
        # LOG.info "AFF = #{s}"
        @affiliation = Affiliation.find_by_id(s)
        ln = n.parent.next_element.next_element.next_element.next_element.next_element.next_element
        # LOG.info "LOCATION: #{ln.content}"
        #parse_location(ln)
      else
        rows = parse_table(n.parent.next_element.next_element)
      end
      table[section_heading] = rows
    end
    table
  end

  # def parse_location(n)
  #   return nil unless n
  #   #LOG.info "LOCATION TEXT\n#{n}"
  #   s1 = n.children.first.content
  #   s2 = n.next_element.children.first.content
  #   #LOG.info "LOCATION 1: #{s1}"
  #   #LOG.info "LOCATION 2: #{s2}"
  #   s1 = s1[(s1.index('(')+1)..(s1.index(')')-1)].strip.to_i if s1.index('(')
  #   s2 = s2[(s2.index('(')+1)..(s2.index(')')-1)].strip.to_i if s2.index('(')
  #   #LOG.info "LOCATION 1: #{s1}"
  #   #LOG.info "LOCATION 2: #{s2}"
  #   if s1 && s2
  #     @cbody = CelestialBody.find_by_cbody_id_and_star_system_id(s1,s2)
  #     @star_system = StarSystem.find_by_id(s2)
  #   elsif s1
  #     @star_system = StarSystem.find_by_id(s1)
  #   end
  #   nil
  # end

  def parse_table(n)
    rows = []
    n.xpath('.//td/table/tr').each do |row|
      cols = []
      row.children.each do |column|
        unless column.content.blank?
          cols << column.content
        end
      end
      # LOG.info cols.join(",")
      rows << cols
    end
    rows
  end
end
