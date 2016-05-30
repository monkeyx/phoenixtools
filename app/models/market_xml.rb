class MarketXml
	def self.fetch!
	    Rails.logger.info "Fetching market data..."
	    
	    doc = Nokogiri::HTML(open(MARKET_XML))

	    e_market = doc.xpath('//markets')

	    market_time = DateTime.parse(e_market.xpath('.//time').first.content)
	    star_date = e_market.xpath('.//stardate').first.content

	    n = Nexus.config
	    n.market_fetched_at = market_time
	    n.save

	    Rails.logger.info "Star Date: #{star_date}"

	    MarketBuy.destroy_all
	    MarketSell.destroy_all
	    
	    e_market.xpath('.//starbase').each do |e_starbase|
	      starbase_id = e_starbase['id'].to_i
	      puts "Starbase: #{starbase_id}"
	      starbase = Base.find_by_id(starbase_id)
	      unless starbase
	        starbase = Base.new
	        starbase.id = starbase_id
	      end
	      aff_tag = e_starbase.xpath('.//aff').first.content
	      affiliation = Affiliation.where(tag: aff_tag).first
	      e_star_system = e_starbase.xpath('.//system').first
	      if e_star_system
	        star_system_id = e_star_system['id'].to_i
	        star_system = StarSystem.find_by_id(star_system_id)
	        unless star_system
	          star_system = StarSystem.new
	          star_system.id = star_system_id
	        end
	        star_system.name = e_star_system.content
	        star_system.save!

	        e_cbody = e_starbase.xpath('.//cbody').first
	        if e_cbody
	          cbody_id = e_cbody['id'].to_i
	          cbody = CelestialBody.where(cbody_id: cbody_id, star_system_id: star_system_id).first
	          cbody = CelestialBody.new unless cbody
	          cbody.cbody_id = cbody_id
	          cbody.star_system = star_system
	          cbody.name = e_cbody.content
	          cbody.save!
	        end
	      end
	      starbase.name = e_starbase.xpath('.//name').first.content
	      starbase.docks = e_starbase.xpath('.//docks').first['quant'].to_i if e_starbase.xpath('.//docks').size > 0
	      starbase.hiports = e_starbase.xpath('.//hiport').first['quant'].to_i if e_starbase.xpath('.//hiport').size > 0
	      starbase.maintenance = e_starbase.xpath('.//maintenance').first['quant'].to_i if e_starbase.xpath('.//maintenance').size > 0
	      starbase.patches = e_starbase.xpath('.//patches').first['price'].to_f if e_starbase.xpath('.//patches').size > 0
	      starbase.affiliation = affiliation if affiliation
	      starbase.celestial_body = cbody if cbody
	      starbase.star_system = star_system if star_system
	      starbase.save!

	      e_starbase.xpath('.//item').each do |e_item|
	        item_id = e_item['id'].to_i
	        item_name = e_item.xpath('.//name').first.content
	        item = Item.find_by_id(item_id)
	        unless item 
	        	item = Item.new(name: item_name)
	        	item.id = item_id
	        	item.save
	        end
	        e_buy = e_item.xpath('.//buy').first if e_item.xpath('.//buy').size > 0
	        e_sell = e_item.xpath('.//sell').first if e_item.xpath('.//sell').size > 0
	        MarketBuy.create!(:item_id => item_id, :base_id => starbase_id, :quantity => e_buy['quant'].to_i, :price => e_buy['price'].to_f) if e_buy
	        MarketSell.create!(:item_id => item_id, :base_id => starbase_id, :quantity => e_sell['quant'].to_i, :price => e_sell['price'].to_f) if e_sell
	      end

	    end
	    Rails.logger.info "Finished market fetch. #{MarketBuy.count} buys and #{MarketSell.count} sells."
	    
	  end
end