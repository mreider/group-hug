class String
  def markdown
    RedCloth.new(self).to_html
  end
end