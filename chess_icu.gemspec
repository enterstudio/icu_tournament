# Generated by jeweler
# DO NOT EDIT THIS FILE
# Instead, edit Jeweler::Tasks in Rakefile, and run `rake gemspec`
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{chess_icu}
  s.version = "0.8.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Mark Orr"]
  s.date = %q{2009-11-22}
  s.email = %q{mark.j.l.orr@googlemail.com}
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = [
    ".gitignore",
     "LICENCE",
     "README.rdoc",
     "Rakefile",
     "VERSION.yml",
     "lib/chess_icu.rb",
     "lib/chess_icu/federation.rb",
     "lib/chess_icu/name.rb",
     "lib/chess_icu/player.rb",
     "lib/chess_icu/result.rb",
     "lib/chess_icu/team.rb",
     "lib/chess_icu/tournament.rb",
     "lib/chess_icu/tournament_fcsv.rb",
     "lib/chess_icu/tournament_krause.rb",
     "lib/chess_icu/util.rb",
     "spec/federation_spec.rb",
     "spec/name_spec.rb",
     "spec/player_spec.rb",
     "spec/result_spec.rb",
     "spec/spec_helper.rb",
     "spec/team_spec.rb",
     "spec/tournament_fcsv_spec.rb",
     "spec/tournament_krause_spec.rb",
     "spec/tournament_spec.rb",
     "spec/util_spec.rb"
  ]
  s.homepage = %q{http://github.com/sanichi/chess_icu}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{For parsing files of chess tournament data into ruby classes.}
  s.test_files = [
    "spec/federation_spec.rb",
     "spec/name_spec.rb",
     "spec/player_spec.rb",
     "spec/result_spec.rb",
     "spec/spec_helper.rb",
     "spec/team_spec.rb",
     "spec/tournament_fcsv_spec.rb",
     "spec/tournament_krause_spec.rb",
     "spec/tournament_spec.rb",
     "spec/util_spec.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<fastercsv>, [">= 1.4.0"])
    else
      s.add_dependency(%q<fastercsv>, [">= 1.4.0"])
    end
  else
    s.add_dependency(%q<fastercsv>, [">= 1.4.0"])
  end
end
