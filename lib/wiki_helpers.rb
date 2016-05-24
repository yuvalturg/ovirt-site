# Various useful functions for Middleman-based sites
class WikiHelpers < Middleman::Extension
  def initialize(app, options_hash = {}, &block)
    super
  end

  helpers do
    def find_wiki_page(searchkey)
      redirects = File.readlines "#{root}/#{source}/redirects.yaml"

      extra = /[#\?].*/
      url_extra = searchkey.match(extra).to_s
      searchkey.gsub!(extra, '')

      match_redir = redirects.map do |line|
        splits = line.split(/:/)
        from = splits.first.strip
        to = splits.last.strip

        if from[/(^|\/)#{searchkey}$/i]
          to.downcase
        end
      end.compact

      sitemap.resources.select do |resource|
        if resource.data.wiki_title
          # Handle redirects
          matches = match_redir.include? resource.data.wiki_title.downcase
          # Check direct matches
          matches ||= resource.data.wiki_title.strip[/(^|\/)#{searchkey}$/i]
        end
      end.map do |resource|
        resource.url + url_extra
      end.first
    end
  end
end

::Middleman::Extensions.register(:wiki_helpers, WikiHelpers)
