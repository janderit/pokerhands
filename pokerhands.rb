require 'minitest/autorun'

TIE=0
BLACK=1
WHITE=2



class PokerHandComparer
  def analyse(line)
    TIE
  end
end




def sample(line, expectation)
  it "correctly analyses sample #{line}" do
    @sut.analyse(line).must_equal expectation
  end
end



describe PokerHandComparer do
  before do
    @sut = PokerHandComparer.new
  end

  sample("Black: 2H 3D 5S 9C KD  White: 2C 3H 4S 8C AH", WHITE)
  sample("Black: 2H 4S 4C 2D 4H  White: 2S 8S AS QS 3S", BLACK)
  sample("Black: 2H 3D 5S 9C KD  White: 2C 3H 4S 8C KH", BLACK)
  sample("Black: 2H 3D 5S 9C KD  White: 2D 3H 5C 9S KH", TIE)

end
