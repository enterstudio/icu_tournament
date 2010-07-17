module ICU

=begin rdoc

== Building a Tournament

One way to create a tournament object is by parsing one of the supported file types (e.g. ICU::Tournament::Krause).
It is also possible to build one programmatically by:

1. creating a bare tournament instance,
2. adding all the players,
3. adding all the results.

For example:

  require 'rubygems'
  require 'icu_tournament'

  t = ICU::Tournament.new('Bangor Masters', '2009-11-09')

  t.add_player(ICU::Player.new('Bobby', 'Fischer', 10))
  t.add_player(ICU::Player.new('Garry', 'Kasparov', 20))
  t.add_player(ICU::Player.new('Mark', 'Orr', 30))

  t.add_result(ICU::Result.new(1, 10, 'D', :opponent => 30, :colour => 'W'))
  t.add_result(ICU::Result.new(2, 20, 'W', :opponent => 30, :colour => 'B'))
  t.add_result(ICU::Result.new(3, 20, 'L', :opponent => 10, :colour => 'W'))

  t.validate!(:rerank => true)

and then:

  serializer = ICU::Tournament::Krause.new
  puts serializer.serialize(@t)

or equivalntly, just:

  puts @t.serialize('Krause')

would result in the following output:

  012 Bangor Masters
  042 2009-11-09
  001   10      Fischer,Bobby                                                      1.5    1    30 w =              20 b 1
  001   20      Kasparov,Garry                                                     1.0    2              30 b 1    10 w 0
  001   30      Orr,Mark                                                           0.5    3    10 b =    20 w 0

Note that the players should be added first because the _add_result_ method will
raise an exception if the players it references through their tournament numbers
(10, 20 and 30 in this example) have not already been added to the tournament.

See ICU::Player and ICU::Result for more details about players and results.


== Validation

A tournament can be validated with either the _validate!_ or _invalid_ methods.
On success, the first returns true while the second returns false.
On error, the first throws an exception while the second returns a string
describing the error.

Validations checks that:

* there are at least two players
* every player has a least one result
* the result round numbers are consistent (no more than one game per player per round)
* the tournament dates (start, finish, round dates), if there are any, are consistent
* the player ranks are consistent with their scores

Side effects of calling _validate!_ or _invalid_ include:

* the number of rounds will be set if not set already
* the finish date will be set if not set already and if there are round dates


== Ranking

The players in a tournament can be ranked by calling the _rerank_ method directly.

  t.rerank

Alternatively they can be ranked as a side effect of validation if the _rerank_ option is set,
but this only applies if the tournament is not yet ranked or it's ranking is inconsistent.

  t.validate(:rerank => true)

Ranking is inconsistent if some but not all players have a rank or if all players
have a rank but some are ranked higher than others on lower scores.

To rank the players requires a tie break method to be specified to order players on the same score.
The default is alphabetical (by last name then first name). Other methods can be specified by supplying
an array of methods (strings or symbols) in order of precedence to the _tie_breaks_ setter. Examples:

  t.tie_breaks = ['Sonneborn-Berger']
  t.tie_breaks = [:buchholz, :neustadtl, :blacks, :wins]
  t.tie_breaks = []  # reset to the default

The full list of supported methods is:

* _Buchholz_: sum of opponents' scores
* _Harkness_ (or _median_): like Buchholz except the highest and lowest opponents' scores are discarded (or two highest and lowest if 9 rounds or more)
* _modified_median_: same as Harkness except only lowest (or highest) score(s) are discarded for players with more (or less) than 50%
* _Neustadtl_ (or _Sonneborn-Berger_): sum of scores of players defeated plus half sum of scores of players drawn against
* _progressive_ (or _cumulative_): sum of running score for each round
* _ratings_: sum of opponents ratings
* _blacks_: number of blacks
* _wins_: number of wins
* _name_: alphabetical by name (if _tie_breaks_ is set to an empty array, as it is initially, then this will be used as the back-up tie breaker)

The return value from _rerank_ is the tournament object itself, to allow chaining, for example:

  t.rerank.renumber


== Renumbering

The numbers used to uniquely identify each player in a tournament can be any set of unique integers
(including zero and negative numbers). To renumber the players so that these numbers start at 1 and
end with the total number of players, use the _renumber_ method. This method takes one optional
argument to specify how the renumbering is done.

  t.renumber(:rank)       # renumber by rank (if there are consistent rankings), otherwise by name alphabetically
  t.renumber              # the same, as renumbering by rank is the default
  t.renumber(:name)       # renumber by name alphabetically
  t.renumber(:order)      # renumber maintaining the order of the original numbers

The return value from _renumber_ is the tournament object itself.

=end

  class Tournament

    extend ICU::Accessor
    attr_date :start
    attr_date_or_nil :finish
    attr_positive_or_nil :rounds
    attr_string %r%[a-z]%i, :name
    attr_string_or_nil %r%[a-z]%i, :city, :type, :arbiter, :deputy
    attr_string_or_nil %r%[1-9]%i, :time_control

    attr_reader :round_dates, :site, :fed, :teams, :tie_breaks

    # Constructor. Name and start date must be supplied. Other attributes are optional.
    def initialize(name, start, opt={})
      self.name  = name
      self.start = start
      [:finish, :rounds, :site, :city, :fed, :type, :arbiter, :deputy, :time_control].each { |a| self.send("#{a}=", opt[a]) unless opt[a].nil? }
      @player = {}
      @teams = []
      @round_dates = []
      @tie_breaks = []
    end

    # Set the tournament federation. Can be _nil_.
    def fed=(fed)
      obj = Federation.find(fed)
      @fed = obj ? obj.code : nil
      raise "invalid tournament federation (#{fed})" if @fed.nil? && fed.to_s.strip.length > 0
    end

    # Add a round date.
    def add_round_date(round_date)
      round_date = round_date.to_s.strip
      parsed_date = Util.parsedate(round_date)
      raise "invalid round date (#{round_date})" unless parsed_date
      @round_dates << parsed_date
      @round_dates.sort!
    end

    # Return the date of a given round, or nil if unavailable.
    def round_date(round)
      @round_dates[round-1]
    end

    # Return the greatest round number according to the players results (which may not be the same as the set number of rounds).
    def last_round
      last_round = 0
      @player.values.each do |p|
        p.results.each do |r|
          last_round = r.round if r.round > last_round
        end
      end
      last_round
    end

    # Set the tournament web site. Should be either unknown (_nil_) or a reasonably valid looking URL.
    def site=(site)
      @site = site.to_s.strip
      @site = nil if @site == ''
      @site = "http://#{@site}" if @site && !@site.match(/^https?:\/\//)
      raise "invalid site (#{site})" unless @site.nil? || @site.match(/^https?:\/\/[-\w]+(\.[-\w]+)+(\/[^\s]*)?$/i)
    end

    # Add a new team. The argument is either a team (possibly already with members) or the name of a new team.
    # The team's name must be unique in the tournament. Returns the the team instance.
    def add_team(team)
      team = Team.new(team.to_s) unless team.is_a? Team
      raise "a team with a name similar to '#{team.name}' already exists" if self.get_team(team.name)
      @teams << team
      team
    end

    # Return the team object that matches a given name, or nil if not found.
    def get_team(name)
      @teams.find{ |t| t.matches(name) }
    end

    # Set the tie break methods.
    def tie_breaks=(tie_breaks)
      raise "argument error - always set tie breaks to an array" unless tie_breaks.class == Array
      # Canonicalise the tie break method names.
      tie_breaks.map! do |m|
        m = m.to_s if m.class == Symbol
        m = m.downcase.gsub(/[-\s]/, '_') if m.class == String
        case m
          when true                then 'name'
          when 'sonneborn_berger'  then 'neustadtl'
          when 'modified_median'   then 'modified'
          when 'median'            then 'harkness'
          when 'cumulative'        then 'progressive'
          else m
        end
      end

      # Check they're all valid.
      tie_breaks.each { |m| raise "invalid tie break method '#{m}'" unless m.to_s.match(/^(blacks|buchholz|harkness|modified|name|neustadtl|progressive|ratings|wins)$/) }

      # Finally set them.
      @tie_breaks = tie_breaks;
    end

    # Add a new player to the tournament. Must have a unique player number.
    def add_player(player)
      raise "invalid player" unless player.class == ICU::Player
      raise "player number (#{player.num}) should be unique" if @player[player.num]
      @player[player.num] = player
    end

    # Get a player by their number.
    def player(num)
      @player[num]
    end

    # Return an array of all players in order of their player number.
    def players
      @player.values.sort_by{ |p| p.num }
    end

    # Lookup a player in the tournament by player number, returning _nil_ if the player number does not exist.
    def find_player(player)
      players.find { |p| p == player }
    end

    # Add a result to a tournament. An exception is raised if the players referenced in the result (by number)
    # do not exist in the tournament. The result, which remember is from the perspective of one of the players,
    # is added to that player's results. Additionally, the reverse of the result is automatically added to the player's
    # opponent, unless the opponent does not exist (e.g. byes, walkovers). By default, if the result is rateable
    # then the opponent's result will also be rateable. To make the opponent's result unrateable, set the optional
    # second parameter to false.
    def add_result(result, reverse_rateable=true)
      raise "invalid result" unless result.class == ICU::Result
      raise "result round number (#{result.round}) inconsistent with number of tournament rounds" if @rounds && result.round > @rounds
      raise "player number (#{result.player}) does not exist" unless @player[result.player]
      @player[result.player].add_result(result)
      if result.opponent
        raise "opponent number (#{result.opponent}) does not exist" unless @player[result.opponent]
        reverse = result.reverse
        reverse.rateable = false unless reverse_rateable
        @player[result.opponent].add_result(reverse)
      end
    end

    # Rerank the tournament by score first and if necessary using a configurable tie breaker method.
    def rerank
      tie_break_methods, tie_break_order, tie_break_hash = tie_break_data
      @player.values.sort do |a,b|
        cmp = 0
        tie_break_methods.each do |m|
          cmp = (tie_break_hash[m][a.num] <=> tie_break_hash[m][b.num]) * tie_break_order[m] if cmp == 0
        end
        cmp
      end.each_with_index do |p,i|
        p.rank = i + 1
      end
      self
    end

    # Return a hash (player number to value) of tie break scores for the main method.
    def tie_break_scores
      tie_break_methods, tie_break_order, tie_break_hash = tie_break_data
      main_method = tie_break_methods[1]
      scores = Hash.new
      @player.values.each { |p| scores[p.num] = tie_break_hash[main_method][p.num] }
      scores
    end

    # Renumber the players according to a given criterion.
    def renumber(criterion = :rank)
      if (criterion.class == Hash)
        # Undocumentted feature - supply your own hash.
        map = criterion
      else
        # Official way of reordering.
        map = Hash.new

        # Renumber by rank only if possible.
        criterion = criterion.to_s.downcase
        if criterion == 'rank'
          begin check_ranks rescue criterion = 'name' end
        end

        # Decide how to renumber.
        if criterion == 'rank'
          # Renumber by rank.
          @player.values.each{ |p| map[p.num] = p.rank }
        elsif criterion == 'order'
          # Just keep the existing numbers in order.
          @player.values.sort_by{ |p| p.num }.each_with_index{ |p, i| map[p.num] = i + 1 }
        else
          # Renumber by name alphabetically.
          @player.values.sort_by{ |p| p.name }.each_with_index{ |p, i| map[p.num] = i + 1 }
        end
      end

      # Apply renumbering.
      @teams.each{ |t| t.renumber(map) }
      @player = @player.values.inject({}) do |hash, player|
        player.renumber(map)
        hash[player.num] = player
        hash
      end

      # Return self for chaining.
      self
    end

    # Is a tournament invalid? Either returns false (if it's valid) or an error message.
    # Has the same _rerank_ option as validate!.
    def invalid(options={})
      begin
        validate!(options)
      rescue => err
        return err.message
      end
      false
    end

    # Raise an exception if a tournament is not valid.
    # The _rerank_ option can be set to _true_ rerank the tournament if ranking is missing or inconsistent.
    def validate!(options={})
      begin check_ranks rescue rerank end if options[:rerank]
      check_players
      check_rounds
      check_dates
      check_teams
      check_ranks(:allow_none => true)
      true
    end

    # Convenience method to serialise the tournament into a supported format.
    # Throws and exception unless the name of a supported format is supplied (e.g. _Krause_).
    def serialize(format)
      serializer = case format.to_s.downcase
        when 'krause'       then ICU::Tournament::Krause.new
        when 'foreigncsv'   then ICU::Tournament::ForeignCSV.new
        when 'swissperfect' then ICU::Tournament::SwissPerfect.new
        else raise "unsupported serialisation format: '#{format}'"
      end
      serializer.serialize(self)
    end

    private

    # Check players.
    def check_players
      raise "the number of players (#{@player.size}) must be at least 2" if @player.size < 2
      @player.each do |num, p|
        raise "player #{num} has no results" if p.results.size == 0
        p.results.each do |r|
          next unless r.opponent
          raise "opponent #{r.opponent} of player #{num} is not in the tournament" unless @player[r.opponent]
        end
      end
    end

    # Round should go from 1 to a maximum, there should be at least one result in every round and,
    # if the number of rounds has been set, it should agree with the largest round from the results.
    def check_rounds
      round = Hash.new
      round_last = last_round
      @player.values.each do |p|
        p.results.each do |r|
          round[r.round] = true
        end
      end
      (1..round_last).each { |r| raise "there are no results for round #{r}" unless round[r] }
      if rounds
        raise "declared number of rounds is #{rounds} but there are results in later rounds, such as #{round_last}" if rounds < round_last
        raise "declared number of rounds is #{rounds} but there are no results with rounds greater than #{round_last}" if rounds > round_last
      else
        self.rounds = round_last
      end
    end

    # Check dates are consistent.
    def check_dates
      raise "start date (#{start}) is after end date (#{finish})" if @start && @finish && @start > @finish
      if @round_dates.size > 0
        raise "the number of round dates (#{@round_dates.size}) does not match the number of rounds (#{@rounds})" unless @round_dates.size == @rounds
        raise "the date of the first round (#{@round_dates[0]}) comes before the start (#{@start}) of the tournament" if @start && @start > @round_dates[0]
        raise "the date of the last round (#{@round_dates[-1]}) comes after the end (#{@finish}) of the tournament" if @finish && @finish < @round_dates[-1]
        @finish = @round_dates[-1] unless @finish
      end
    end

    # Check teams. Either there are none or:
    # * every team member is a valid player, and
    # * every player is a member of exactly one team.
    def check_teams
      return if @teams.size == 0
      member = Hash.new
      @teams.each do |t|
        t.members.each do |m|
          raise "member #{m} of team '#{t.name}' is not a valid player number for this tournament" unless @player[m]
          raise "member #{m} of team '#{t.name}' is already a member of team #{member[m]}" if member[m]
          member[m] = t.name
        end
      end
      @player.keys.each do |p|
        raise "player #{p} is not a member of any team" unless member[p]
      end
    end

    # Check if the players ranking is consistent, which will be true if:
    # * every player has a rank
    # * no two players have the same rank
    # * the highest rank is 1
    # * the lowest rank is equal to the total of players
    def check_ranks(options={})
      ranks = Hash.new
      @player.values.each do |p|
        if p.rank
          raise "two players have the same rank #{p.rank}" if ranks[p.rank]
          ranks[p.rank] = p
        end
      end
      return if ranks.size == 0 && options[:allow_none]
      raise "every player has to have a rank" unless ranks.size == @player.size
      by_rank = @player.values.sort{ |a,b| a.rank <=> b.rank}
      raise "the highest rank must be 1" unless by_rank[0].rank == 1
      raise "the lowest rank must be #{ranks.size}" unless by_rank[-1].rank == ranks.size
      if by_rank.size > 1
        (1..by_rank.size-1).each do |i|
          p1 = by_rank[i-1]
          p2 = by_rank[i]
          raise "player #{p1.num} with #{p1.points} points is ranked above player #{p2.num} with #{p2.points} points" if p1.points < p2.points
        end
      end
    end

    # Return an array of tie break methods and an array of tie break orders (+1 for asc, -1 for desc).
    # The first and most important method is always "score", the last and least important is always "name".
    def tie_break_data

      # Construct the arrays and hashes to be returned.
      methods, order, data = Array.new, Hash.new, Hash.new

      # Score is always the most important.
      methods << 'score'
      order['score'] = -1

      # Add the configured methods.
      tie_breaks.each do |m|
        methods << m
        order[m] = m == 'name' ? 1 : -1
      end

      # Name is included as the last and least important tie breaker unless it's already been added.
      unless methods.include?('name')
        methods << 'name'
        order['name'] = 1
      end

      # We'll need the number of rounds.
      rounds = last_round

      # Pre-calculate some scores that are not in themselves tie break scores
      # but are needed in the calculation of some of the actual tie-break scores.
      pre_calculated = Array.new
      pre_calculated << 'opp-score'  # sum scores where a non-played games counts 0.5
      pre_calculated.each do |m|
        data[m] = Hash.new
        @player.values.each { |p| data[m][p.num] = tie_break_score(data, m, p, rounds) }
      end

      # Now calculate all the other scores.
      methods.each do |m|
        next if pre_calculated.include?(m)
        data[m] = Hash.new
        @player.values.each { |p| data[m][p.num] = tie_break_score(data, m, p, rounds) }
      end

      # Finally, return what we calculated.
      [methods, order, data]
    end

    # Return a tie break score for a given player and a given tie break method.
    def tie_break_score(hash, method, player, rounds)
      case method
        when 'score'       then player.points
        when 'wins'        then player.results.inject(0)   { |t,r| t + (r.opponent && r.score  == 'W' ? 1 : 0) }
        when 'blacks'      then player.results.inject(0)   { |t,r| t + (r.opponent && r.colour == 'B' ? 1 : 0) }
        when 'buchholz'    then player.results.inject(0.0) { |t,r| t + (r.opponent ? hash['opp-score'][r.opponent] : 0.0) }
        when 'neustadtl'   then player.results.inject(0.0) { |t,r| t + (r.opponent ? hash['opp-score'][r.opponent] * r.points : 0.0) }
        when 'opp-score'   then player.results.inject(0.0) { |t,r| t + (r.opponent ? r.points : 0.5) } + (rounds - player.results.size) * 0.5
        when 'progressive' then (1..rounds).inject(0.0)    { |t,n| r = player.find_result(n); s = r ? r.points : 0.0; t + s * (rounds + 1 - n) }
        when 'ratings'     then player.results.inject(0)   { |t,r| t + (r.opponent && @player[r.opponent].rating ? @player[r.opponent].rating : 0) }
        when 'harkness', 'modified'
          scores = player.results.map{ |r| r.opponent ? hash['opp-score'][r.opponent] : 0.0 }.sort
          1.upto(rounds - player.results.size) { scores << 0.0 }
          half = rounds / 2.0
          times = rounds >= 9 ? 2 : 1
          if method == 'harkness' || player.points == half
            1.upto(times) { scores.shift; scores.pop }
          else
            1.upto(times) { scores.send(player.points > half ? :shift : :pop) }
          end
          scores.inject(0.0) { |t,s| t + s }
        else player.name
      end
    end
  end
end
