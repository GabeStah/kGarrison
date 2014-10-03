class StaticPagesController < ApplicationController
  def index
    Parse.parse('http://wod.wowhead.com/mission=328')
  end
end
