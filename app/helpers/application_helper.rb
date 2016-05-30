module ApplicationHelper
  def title(title)
    content_for(:title, title)
  end

  def heading(heading)
    content_for(:heading, heading)
  end

  def js(script)
    content_for(:jscript, script)
  end

  def fetched_date(date)
    date ? date.to_formatted_s(:long) : 'Never'
  end

  def loc(sys,cbody)
    l = ''
    l = link_to(sys, sys) if sys
    l = "#{link_to(cbody, cbody)}, #{l}" if cbody
    l.html_safe
  end

  def page_numbers(models)
    content_for(:page_numbers, paginate(models))
  end

  def fetch_button_form(text, target, updating, button_css='btn-primary')
    if updating
       disabled = " disabled"
       text = "#{text} (In Progress)"
     else
       disabled = ""
    end
    link_to(text, target, :class => "btn btn-lg#{disabled} #{button_css}", :role => "button")
  end

  def weeks_trade_css_class(weeks)
    if weeks
      if weeks == "N/A"
        return "text-muted"
      elsif weeks == "< 1" || weeks < Base::MAXIMUM_WEEKS_TRADE_RESERVES
        return "text-success"
      else
        return "text-danger"
      end
    else
      return "text-muted"
    end
  end

  def orders_box(orders)
    return '' unless orders && orders.size > 0
    rows = (orders.size < 8 ? 8 : orders.size > 30 ? 30 : orders.size)
    s = "<textarea rows='#{rows}' cols='60'>\n"
    s = s + orders.join("\n")
    s = s + "</textarea>\n"
    s
  end
end
