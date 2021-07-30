require_relative '../_plugins/page_tree'

def test
  root = PageTree.new(0, '', '', { '/foo/' => 'Foo Dir' })
  root.add_file_path(SourcePage.new('/rootfile.html', 'Root File', 0))
  root.add_file_path(SourcePage.new('/foo/foo.html', 'Foo', 0))
  root.add_file_path(SourcePage.new('/bar/bar.html', 'Bar', 0))
  root.add_file_path(SourcePage.new('/a/b/c/d2.html', 'D2', 0))
  root.add_file_path(SourcePage.new('/a/b/c/d1.html', 'D1', 0))
  root.add_file_path(SourcePage.new('/a/aa/aaa/aaaa.html', 'AAAA', 0))
  root.add_file_path(SourcePage.new('/a/aa.html', 'AA', 0))
  puts 'PRINTING PAGE TREE'
  puts root.to_s
  puts 'PRINTING SUB TREE'
  puts root.subtree_at('/a/b/c/README.html')
end

test