require "spec"
require "../src/filechecker"

FOO = "#{__DIR__}/testcase/foo"
BAR = "#{__DIR__}/testcase/bar"

LOG = Logger.new STDOUT
LOG.level = Logger::DEBUG if ENV["FC_DEBUG"]? == "1"

FOO_CHECKER = FileChecker::Checker.new FOO, LOG, %w(.ignore)
BAR_CHECKER = FileChecker::Checker.new BAR, LOG, %w(.ignore)
