require 'minitest/autorun'


Card = Struct.new(:value,:suit)

CLUBS="C"
SPADES="S"
HEARTS="H"
DIAMONDS="D"

TWO="2"
THREE="3"
FOUR="4"
FIVE="5"
SIX="6"
SEVEN="7"
EIGHT="8"
NINE="9"
TEN="T"
JACK="J"
QUEEN="Q"
KING="K"
ACE="A"



class PokerHandParser
  def parseHand(hand)
  end

  def parseBlackWhiteLine(line)
  end
end

class PokerHandEvaluator
  def evaluateHand(hand)
  end
end


TIE=0
BLACK=1
WHITE=2



class PokerHandComparer

  def initialize(parser, evaluator)
    @parser=parser
    @evaluator=evaluator
  end

  def compare(black, white)
    TIE
  end
  
  def analyse(line)
    hands=@parser.parseBlackWhiteLine(line)
    black=@evaluator.evaluateHand(hands[:black])
    white=@evaluator.evaluateHand(hands[:white])
    compare(black, white)
  end

end



describe PokerHandParser do
  before do
    @sut = PokerHandParser.new
  end

  it "parses a partial hand" do
    @sut.parseHand("JS 5D").must_equal [Card.new(JACK,SPADES),Card.new(FIVE,DIAMONDS)]
  end

end


describe PokerHandEvaluator do
  before do
    @sut = PokerHandEvaluator.new
  end

end





def sample(line, expectation)
  it "correctly analyses sample #{line}" do
    @sut.analyse(line).must_equal expectation
  end
end

describe PokerHandComparer do
  before do
    @sut = PokerHandComparer.new(PokerHandParser.new, PokerHandEvaluator.new)
  end

#  sample("Black: 2H 3D 5S 9C KD  White: 2C 3H 4S 8C AH", WHITE)
#  sample("Black: 2H 4S 4C 2D 4H  White: 2S 8S AS QS 3S", BLACK)
#  sample("Black: 2H 3D 5S 9C KD  White: 2C 3H 4S 8C KH", BLACK)
#  sample("Black: 2H 3D 5S 9C KD  White: 2D 3H 5C 9S KH", TIE)

end
