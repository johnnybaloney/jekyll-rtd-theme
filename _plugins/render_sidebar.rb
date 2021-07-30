module Jekyll
  class RenderSidebar < Liquid::Tag

    def initialize(tag_name, text, tokens)
      super
      @text = text
    end

    def top_level_page_link(page, root, current_page_path)
      current = current_page_path == "/#{page.file}" ? "current" : ""
      link = "<li class=\"toc level-#{root.depth + 1} #{current}\" data-sort=\"#{page.sort}\" data-level=\"#{root.depth + 1}\">"
      link += "<a class=\"d-flex flex-items-baseline \" href=\"/#{page.file}\">#{page.title}</a>"
      link += "</li>"
      link
    end

    def subdirectory_links(subdirectories, current_page_path)
      links = ''
      subdirectories.each do |subdir|
        if subdir.depth == 1
          # SUBDIRECTORIES - LEVEL 1
          links += "<a class=\"caption d-block text-uppercase no-wrap px-2 py-0\" href=\"#{subdir.directory_path}\">"
        else
          # SUBDIRECTORIES - LEVEL 2+
          links += "<li class=\"toc level-#{subdir.depth - 1}\">"
          links += "<a class=\"d-flex flex-items-baseline\" href=\"#{subdir.directory_path}\">"
        end
        links += subdir.directory_title != nil ? subdir.directory_title : subdir.directory
        links += "</a>"
        links += "<ul>" # former '_toctree.liquid' start
        subdir.pages.each do |page|
          current = current_page_path == "#{subdir.directory_path}#{page.file}" ? "current" : ""
          links += "<li class=\"toc level-#{subdir.depth} #{current}\" data-sort=\"#{page.sort}\" data-level=\"#{subdir.depth}\">"
          links += "<a class=\"d-flex flex-items-baseline \" href=\"#{subdir.directory_path}#{page.file}\">"
          links += (page.sort != nil ? "#{page.sort}. " : "") + page.title
          links += "</a></li>"
        end
        if subdir.subdirectories.length > 0
          links += subdirectory_links(subdir.subdirectories, current_page_path)
        end
        links += "</ul>" # former '_toctree.liquid' end
        if subdir.depth > 1
          links += "</li>"
        end
      end
      links
    end

    def render_sidebar(root, current_page_path)
      # ROOT PAGES - LEVEL 0
      sidebar = "<ul>" # former 'toctree.liquid' start
      root.pages.each do |page|
        sidebar += top_level_page_link(page, root, current_page_path)
      end
      sidebar += "</ul>" # former 'toctree.liquid' end
      sidebar += subdirectory_links(root.subdirectories, current_page_path)
      sidebar
    end

    def render(context)
      # path of the currently processed page
      current_page_path = lookup(context, 'page.url')
      page_tree = prepare_page_tree(context)
      render_sidebar(page_tree, current_page_path)
    end
  end
end

Liquid::Template.register_tag('render_sidebar', Jekyll::RenderSidebar)

