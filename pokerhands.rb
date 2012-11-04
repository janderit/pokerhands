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
  attr_reader :precedence,:kickers,:majorvalue,:minorvalue
end

class HighCard < PokerHand
  def initialize(hand)
    @card=hand.max{|a,b| a.value<=>b.value}
    @majorvalue=@card.value()
    @minorvalue=@card.value()
    @precedence=1
    @kickers=hand-[@card]
  end
  def to_s()
    "High card #{@card.rank}"
  end
end

class Pair < PokerHand
  def initialize(hand)
    pairs=hand.select{|x|hand.select{|y|y.rank==x.rank}.count>1}
    pairs=pairs.uniq{|c|c.rank}

    if pairs.count==0
        @precedence=0
        @kickers=nil
        @majorvalue=0
        @minorvalue=0
    else
        @card=pairs.max{|a,b|a.value<=>b.value}
        @majorvalue=@card.value()
        @minorvalue=@card.value()
        @precedence=2
        @kickers=hand.select{|c|c.rank!=@card.rank}
    end
  end
  def to_s()
    "One pair #{@card.rank}"
  end
end

class TwoPairs < PokerHand
  def initialize(hand)
    pairs=hand.select{|x|hand.select{|y|y.rank==x.rank}.count>1}
    pairs=pairs.uniq{|c|c.rank}

    if pairs.count<2
        @precedence=0
        @kickers=nil
        @majorvalue=0
        @minorvalue=0
    else
        @carda=pairs.max{|a,b|a.value<=>b.value}
        @cardb=pairs.min{|a,b|a.value<=>b.value}
        @majorvalue=@carda.value()
        @minorvalue=@cardb.value()
        @precedence=3
        @kickers=hand.select{|c|c.rank!=@carda.rank&&c.rank!=@cardb.rank}
    end
  end
  attr_reader :carda,:cardb
  def to_s()
    "Two pairs #{@carda.rank} and #{@cardb.rank}"
  end
end

class Triplet < PokerHand
  def initialize(hand)
    triplets=hand.select{|x|hand.select{|y|y.rank==x.rank}.count>2}
    triplets=triplets.uniq{|c|c.rank}

    if triplets.count==0
        @precedence=0
        @kickers=nil
        @majorvalue=0
        @minorvalue=0
    else
        @card=triplets.max{|a,b|a.value<=>b.value}
        @majorvalue=@card.value()
        @minorvalue=@card.value()
        @precedence=4
        @kickers=hand.select{|c|c.rank!=@card.rank}
    end
  end
  attr_reader :card
  def to_s()
    "Three of a kind #{@card.rank}"
  end
end

class Quadriga < PokerHand
  def initialize(hand)
    quadriga=hand.select{|x|hand.select{|y|y.rank==x.rank}.count>3}
    quadriga=quadriga.uniq{|c|c.rank}

    if quadriga.count==0
        @precedence=0
        @kickers=nil
        @majorvalue=0
        @minorvalue=0
    else
        @card=quadriga.max{|a,b|a.value<=>b.value}
        @majorvalue=@card.value()
        @minorvalue=@card.value()
        @precedence=8
        @kickers=hand.select{|c|c.rank!=@card.rank}
    end
  end
  def to_s()
    "Four of a kind #{@card.rank}"
  end
end

class FullHouse<PokerHand
  def initialize(hand)
    three=Triplet.new(hand)
    pairs=TwoPairs.new(hand)
    kickers=nil
    if three.precedence>0 && pairs.precedence>0
        @precedence=7
        @carda=three.card
        @cardb=pairs.carda unless (pairs.carda.rank==@carda.rank)
        @cardb=pairs.cardb if (pairs.carda.rank==@carda.rank)
        @majorvalue=@carda.value()
        @minorvalue=@cardb.value()
    else
        @precedence=0
    end
  end
  def to_s()
    "Full house #{@carda.rank} and #{@cardb.rank}"
  end
end

class Flush < PokerHand
  def initialize(hand)
    flush=hand.select{|x|hand.select{|y|y.suit==x.suit}.count==5}
    flush=flush.uniq{|c|c.suit}

    @kickers=nil
    if flush.count==0
        @precedence=0
        @majorvalue=0
        @minorvalue=0
    else
        @card=flush.max{|a,b|a.value<=>b.value}
        @majorvalue=1
        @minorvalue=1
        @precedence=6
    end
  end
  def to_s()
    "Flush #{@card.suit}"
  end
end

class Straight < PokerHand
  def initialize(hand)

    cards=hand.sort_by{|c|-c.value}

    straight=true

    for i in 0..3 do
        straight=false if cards[i].value!=cards[i+1].value+1
    end

    @kickers=nil
    if straight
        @card=cards.first
        @majorvalue=@card.value()
        @minorvalue=@card.value()
        @precedence=5
    else
        @precedence=0
        @majorvalue=0
        @minorvalue=0
    end
  end
  attr_reader :card
  def to_s()
    "Straight from #{@card}"
  end

end

class StraightFlush<PokerHand
  def initialize(hand)
    flush=Flush.new(hand)
    straight=Straight.new(hand)
    kickers=nil
    if flush.precedence>0 && straight.precedence>0
        @precedence=9
        @card=straight.card
        @majorvalue=@card.value()
        @minorvalue=@card.value()
    else
        @precedence=0
    end
  end
  def to_s()
    "Straight flush from #{@card}"
  end
end

class RoyalFlush<PokerHand
  def initialize(hand)
    flush=Flush.new(hand)
    straight=Straight.new(hand)
    kickers=nil
    if flush.precedence>0 && straight.precedence>0 && straight.card.rank==ACE
        @precedence=10
        @card=straight.card
        @majorvalue=@card.value()
        @minorvalue=@card.value()
    else
        @precedence=0
    end
  end
  def to_s()
    "Royal flush from #{@card}"
  end
end









class PokerHandEvaluator
  def evaluateHand(hand)
    result=[HighCard.new(hand),Pair.new(hand),TwoPairs.new(hand),Triplet.new(hand),Quadriga.new(hand),FullHouse.new(hand),Flush.new(hand),Straight.new(hand),StraightFlush.new(hand),RoyalFlush.new(hand)]
    return result.max{|a,b|a.precedence<=>b.precedence}
  end
end


TIE=0
BLACK=1
WHITE=2


WinningHand=Struct.new(:winner, :info)

class PokerHandComparer

  def initialize(parser, evaluator)
    @parser=parser
    @evaluator=evaluator
  end

  def doCompareKickers(black, white, blackkickers, whitekickers)
    return WinningHand.new(TIE, "Both hands: #{black}, equal kickers") if (blackkickers.count==0)
    maxblack=blackkickers.max{|a,b|a.value<=>b.value}
    maxwhite=whitekickers.max{|a,b|a.value<=>b.value}
    return WinningHand.new(BLACK,"#{black}, kicker: #{maxblack}") if (maxblack.value>maxwhite.value) 
    return WinningHand.new(WHITE,"#{white}, kicker: #{maxwhite}") if (maxblack.value<maxwhite.value) 
    doCompareKickers(black,white,blackkickers-[maxblack],whitekickers-[maxwhite])
  end

  def compareKickers(black, white)
    return WinningHand.new(TIE, "Both hands: #{black}") if (black.kickers==nil)
    raise "WTF" if (black.kickers.count!=white.kickers.count)
    doCompareKickers(black, white, black.kickers, white.kickers)
  end

  def compareEqual(black, white)
    return WinningHand.new(BLACK,black) if (black.majorvalue>white.majorvalue) 
    return WinningHand.new(WHITE,white) if (black.majorvalue<white.majorvalue) 
    return WinningHand.new(BLACK,black) if (black.minorvalue>white.minorvalue) 
    return WinningHand.new(WHITE,white) if (black.minorvalue<white.minorvalue) 
    compareKickers(black, white)
  end

  def compare(black, white)
    return compareEqual(black,white) if (black.precedence==white.precedence)
    return WinningHand.new(BLACK,black) if (black.precedence>white.precedence)
    return WinningHand.new(WHITE,white) if (black.precedence<white.precedence)
    raise("WTF")
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
    hand = @sut.evaluateHand(@parser.parseHand("TC 6H AD QS 2S"))
    hand.must_be_instance_of HighCard
    hand.majorvalue.must_equal 14
    hand.minorvalue.must_equal 14
    hand.precedence.must_equal 1
  end

  it "identifies the high card's kickers" do
    hand = @sut.evaluateHand(@parser.parseHand("TC 6H AD QS 2S"))
    hand.must_be_instance_of HighCard
    hand.kickers.count.must_equal 4
    hand.kickers.max{|a,b|a.value<=>b.value}.must_equal Card.new(QUEEN,SPADES)
  end

  it "identifies a pair" do
    hand = @sut.evaluateHand(@parser.parseHand("TC 6H 6D QS 2S"))
    hand.must_be_instance_of Pair
    hand.majorvalue.must_equal 6
    hand.minorvalue.must_equal 6
    hand.precedence.must_equal 2
  end

  it "identifies the pair's kickers" do
    hand = @sut.evaluateHand(@parser.parseHand("TC 6H 6D QS 2S"))
    hand.must_be_instance_of Pair
    hand.kickers.count.must_equal 3
    hand.kickers.max{|a,b|a.value<=>b.value}.must_equal Card.new(QUEEN,SPADES)
  end

  it "identifies two pairs" do
    hand = @sut.evaluateHand(@parser.parseHand("TC 6H 6D QS QS"))
    hand.must_be_instance_of TwoPairs
    hand.majorvalue.must_equal 12 
    hand.minorvalue.must_equal 6
    hand.precedence.must_equal 3
  end

  it "identifies the twopair's kicker" do
    hand = @sut.evaluateHand(@parser.parseHand("TC 6H 6D QS QS"))
    hand.must_be_instance_of TwoPairs
    hand.kickers.count.must_equal 1
    hand.kickers.first.must_equal Card.new(TEN,CLUBS)
  end

  it "detects a straight" do
    hand = @sut.evaluateHand(@parser.parseHand("KC QH JD TS 9S"))
    hand.must_be_instance_of Straight
    hand.majorvalue.must_equal 13 
    hand.minorvalue.must_equal 13
    hand.precedence.must_equal 5
 
  end






end





def sample(line, expectation)
  it "correctly analyses sample #{line}" do
    result=@sut.analyse(line)
    puts("#{result.info}  --  #{line}")
    result.winner.must_equal expectation
  end
end

describe PokerHandComparer do
  before do
    @sut = PokerHandComparer.new(PokerHandParser.new, PokerHandEvaluator.new)
  end

  sample("Black: 2H 3D 5S 9C KD  White: 2C 3H 4S 8C AH", WHITE)
  sample("Black: 2H 4S 4C 2D 4H  White: 2S 8S AS QS 3S", BLACK)
  sample("Black: 2H 4S 4C 2D 4H  White: 2C 8S AS QS 3S", BLACK)
  sample("Black: 2H 6S 4C 2D 4H  White: 5S KS AS QS KS", WHITE)
  sample("Black: 2H 2S 4C 2D 4H  White: KD KH AS QS KS", BLACK)
  sample("Black: 2H 3D 5S 9C KD  White: 2C 3H 4S 8C KH", BLACK)
  sample("Black: 2H 3D 5S 9C KD  White: 2D 3H 5C 9S KH", TIE)

  sample("Black: 2H 3D 5S 5C KD  White: 2D 4H 5H 5D KH", WHITE)

  sample("Black: 2H 4S 4C 2D 4H  White: 3S 3C 3H 3D 6S", WHITE)
  sample("Black: 9H QS TC JD KH  White: JS QC KS TD AS", WHITE)
  sample("Black: 9H QS TC JD KH  White: 2S 3C 3H 3D 6S", BLACK)

  sample("Black: 9H QH TH JH KH  White: JS QC KS TD AS", BLACK)
  sample("Black: 9S QS TC JD KS  White: JH QH KH TH AH", WHITE)

end
