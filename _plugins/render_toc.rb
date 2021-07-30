module Jekyll
  class RenderTOC < Liquid::Tag

    NEWLINE = "\n"

    def initialize(tag_name, text, tokens)
      super
      @text = text
    end

    def render_level(subtree, indent)
      toc = subtree.pages.map { |page| ' ' * indent + "- [#{page.title}](#{page.path})" }.to_a.join(NEWLINE) + NEWLINE
      subtree.subdirectories.map { |subdir|
        toc += ' ' * indent + "- [#{subdir.directory_title}](#{subdir.directory_path}):#{NEWLINE}"
        toc += render_level(subdir, indent + 4)
      }
      toc
    end

    def render_toc(root, current_page_path)
      subtree = root.subtree_at(current_page_path)
      render_level(subtree, 0)
    end

    def render(context)
      # path of the currently processed page
      current_page_path = lookup(context, 'page.url')
      page_tree = prepare_page_tree(context)
      render_toc(page_tree, current_page_path)
    end
  end
end

Liquid::Template.register_tag('render_toc', Jekyll::RenderTOC)

