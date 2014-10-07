class String
  def is_i?
    !!(self =~ /\A[-+]?[0-9]+\z/)
  end
  def string_between_markers marker1, marker2
    self[/#{Regexp.escape(marker1)}(.*?)#{Regexp.escape(marker2)}/m, 1]
  end
end