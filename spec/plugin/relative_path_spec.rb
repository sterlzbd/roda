require_relative "../spec_helper"

describe "relative_plath plugin" do 
  it "supports relative_path method to turn absolute paths into relative paths" do
    app(:relative_path) do
      relative_path("/a")
    end

    body.must_equal './a'
    body('/a').must_equal './a'
    body('/a/').must_equal '../a'
    body('/a/b').must_equal '../a'
    body('/a/b/c').must_equal '../../a'
    body('/a/b/c', 'SCRIPT_NAME'=>'/d').must_equal '../../../a'
    body('', 'SCRIPT_NAME'=>'/d').must_equal './a'
    body('', 'SCRIPT_NAME'=>'').must_equal '/a'
    body('a', 'SCRIPT_NAME'=>'').must_equal '/a'
    body('/', 'SCRIPT_NAME'=>'d').must_equal '/a'
  end

  it "supports relative_prefix method for prefix to turn absolute paths into relative paths" do
    app(:relative_path) do
      "#{relative_prefix}/a"
    end

    body.must_equal './a'
    body('/a').must_equal './a'
    body('/a/').must_equal '../a'
    body('/a/b').must_equal '../a'
    body('/a/b/c').must_equal '../../a'
    body('/a/b/c', 'SCRIPT_NAME'=>'/d').must_equal '../../../a'
    body('', 'SCRIPT_NAME'=>'/d').must_equal './a'
    body('', 'SCRIPT_NAME'=>'').must_equal '/a'
    body('a', 'SCRIPT_NAME'=>'').must_equal '/a'
    body('/', 'SCRIPT_NAME'=>'d').must_equal '/a'
  end
end
