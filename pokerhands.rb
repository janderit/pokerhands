require 'minitest/autorun'


Card = Struct.new(:rank,:suit) do
  def value()
    case rank
      when ACE then 14
      when KING then 13
      when QUEEN then 12
      when JACK then 11
      when TEN then 10
      else rank.to_i
    end
  end 
  def to_s()
    "#{rank}#{suit}"
  end
end

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

  def parseCard(card)
    Card.new(card[0],card[1])
  end

  def parseHand(hand)
    hand.scan(/[2-9TJQKA][CSHD]/).map{|card|parseCard(card)}
  end

  def parseBlackWhiteLine(line)
    hands=line.scan(/(Black|White):\W(\w\w\W\w\w\W\w\w\W\w\w\W\w\w)/)
    {:black=>hands.select{|x|x[0]=="Black"}.map{|h|parseHand(h[1])}.first, 
     :white=>hands.select{|x|x[0]=="White"}.map{|h|parseHand(h[1])}.first}
  end
end

class PokerHand
  attr_reader :precedence,:kickers
end

class HighCard < PokerHand
  attr_reader :card,:value
  def initialize(hand)
    @card=hand.max{|a,b| a.value<=>b.value}
    @value=@card.value()
    @precedence=1
    @kickers=hand-[@card]
  end
  def to_s()
    "High card #{@card}"
  end
end

class PokerHandEvaluator
  def evaluateHand(hand)
    result=[]
    cand=HighCard.new(hand)
    result+=[cand] if (cand.precedence>0)
    return result
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


describe Card do
  it "has a value" do
    c=Card.new(QUEEN, SPADES)
    c.value.must_equal 12
  end
end


describe PokerHandParser do
  before do
    @sut = PokerHandParser.new
  end

  it "parses a normal card" do
    @sut.parseCard("5D").must_equal Card.new(FIVE,DIAMONDS)
    @sut.parseCard("5D").value.must_equal 5
  end

  it "parses a high card" do
    @sut.parseCard("KC").must_equal Card.new(KING,CLUBS)
    @sut.parseCard("KC").value.must_equal 13 
  end

  it "parses a partial hand" do
    @sut.parseHand("JS 5D").must_equal [Card.new(JACK,SPADES),Card.new(FIVE,DIAMONDS)]
  end

  it "parses black and white into two hands" do
    @sut.parseBlackWhiteLine("Black: 2H 3D 5S 9C KD  White: 2C 3H 4S 8C KH").count.must_equal 2
  end
  it "parsed hands contain five cards" do
    @sut.parseBlackWhiteLine("Black: 2H 3D 5S 9C KD  White: 2C 3H 4S 8C KH")[:black].count.must_equal 5
    @sut.parseBlackWhiteLine("Black: 2H 3D 5S 9C KD  White: 2C 3H 4S 8C KH")[:white].count.must_equal 5
  end
  it "parsed hands are correct" do
    @sut.parseBlackWhiteLine("Black: 2H 3D 5S 9C KD  White: 2C 3H 4S 8C KH")[:black].must_equal [Card.new(TWO,HEARTS),Card.new(THREE,DIAMONDS),Card.new(FIVE,SPADES),Card.new(NINE,CLUBS),Card.new(KING,DIAMONDS)]
    @sut.parseBlackWhiteLine("Black: 2H 3D 5S 9C KD  White: 2C 3H 4S 8C KH")[:white].must_equal [Card.new(TWO,CLUBS),Card.new(THREE,HEARTS),Card.new(FOUR,SPADES),Card.new(EIGHT,CLUBS),Card.new(KING,HEARTS)]
  end

end


describe PokerHandEvaluator do
  before do
    @parser=PokerHandParser.new
    @sut = PokerHandEvaluator.new
  end

  it "identifies the high card" do
    hands = @sut.evaluateHand(@parser.parseHand("TC 6H AD QS 2S"))
    hands.count.must_equal 1
    hand=hands.first
    hand.must_be_instance_of HighCard
    hand.card.must_equal Card.new(ACE,DIAMONDS)
    hand.value.must_equal 14
    hand.precedence.must_equal 1
  end

  it "identifies the high card's kickers" do
    hands = @sut.evaluateHand(@parser.parseHand("TC 6H AD QS 2S"))
    hands.count.must_equal 1
    hand=hands.first
    hand.must_be_instance_of HighCard
    hand.kickers.count.must_equal 4
    @sut.evaluateHand(hand.kickers).first.card.must_equal Card.new(QUEEN,SPADES)
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
