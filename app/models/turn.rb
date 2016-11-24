module Turn

  def get_turn!
    code, turn = Nexus.html_client.get_turn(self.id)
    if code == 200
      LOG.info "Fetched turn for #{self}: #{turn.name} - #{turn.affiliation}"
      unless turn.name == self.name
        LOG.info "#{self} changed name to #{turn.name}"
        update_attributes!(:name => turn.name)
      end
      unless turn.affiliation == self.affiliation
        LOG.info "#{self} changed affiliation to #{turn.affiliation}"
        update_attributes!(:affiliation_id => turn.affiliation.id)
      end
      return turn
    else
      LOG.error "Failed to fetch turn for #{self} - #{code}"
      return false
    end
  end

  def update_item_resources!(turn)
    self.base_resources.destroy_all
    turn.resources.each do |resource|
      # LOG.info resource
      br = BaseResource.create!(:base_id => self.id, 
        :item_id => resource[:item] ? resource[:item].id : nil, 
        :resource_id => resource[:resource_id].to_i, 
        :resource_drop => resource[:resource_drop].to_i,
        :resource_yield => resource[:resource_yield].to_f,
        :ore_mines => resource[:ore_mines] ? resource[:ore_mines].to_i : 0,
        :resource_complexes => resource[:resource_complexes] ? resource[:resource_complexes].to_i : 0,
        :resource_size => resource[:resource_size] != 'Infinite' ? resource[:resource_size].to_i : -999)
    end
  end
  
end
