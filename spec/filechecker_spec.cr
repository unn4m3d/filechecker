require "./spec_helper"

describe FileChecker::Checker do
  it "works" do
    FOO_CHECKER.compare(BAR_CHECKER.obtain(%w(SHA256)), diff_only: true).result.should eq({
      "foo/foo.cpp" => FileChecker::Result.new(FileChecker::FileState::CORRUPT, "SHA256"),
      "bar.txt" => FileChecker::Result.new(FileChecker::FileState::REDUNDANT, nil),
      "baz.txt" => FileChecker::Result.new(FileChecker::FileState::MISSING, nil)
      })
  end
end
