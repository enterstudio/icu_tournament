# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{chess_icu}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Mark Orr"]
  s.date = %q{2009-04-11}
  s.email = %q{mark.j.l.orr@googlemail.com}
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = [
    ".gitignore",
    "CHANGELOG",
    "LICENCE",
    "README.rdoc",
    "Rakefile",
    "VERSION.yml",
    "lib/chess_icu.rb",
    "lib/name.rb",
    "lib/player.rb",
    "lib/result.rb",
    "lib/tournament.rb",
    "lib/tournament_fcsv.rb",
    "lib/util.rb",
    "spec/name_spec.rb",
    "spec/player_spec.rb",
    "spec/result_spec.rb",
    "spec/spec_helper.rb",
    "spec/tournament_fcsv_spec.rb",
    "spec/tournament_spec.rb",
    "spec/util_spec.rb"
  ]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/sanichi/chess_icu}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{For parsing files of chess tournament data into ruby classes.}
  s.test_files = [
    "spec/name_spec.rb",
    "spec/player_spec.rb",
    "spec/result_spec.rb",
    "spec/spec_helper.rb",
    "spec/tournament_fcsv_spec.rb",
    "spec/tournament_spec.rb",
    "spec/util_spec.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
