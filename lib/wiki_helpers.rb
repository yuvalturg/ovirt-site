# Various useful functions for Middleman-based sites
class WikiHelpers < Middleman::Extension
  def initialize(app, options_hash = {}, &block)
    super
  end

  helpers do
    def load_redirects
      return $helper_wiki_redirects if $helper_wiki_redirects

      slashes = /^\/|\/$/

      redirects = File.readlines "#{root}/#{source}/redirects.yaml"

      $helper_wiki_redirects ||= redirects.map do |line|
        splits = line.split(':')

        {
          from: splits.first.gsub(slashes, '').strip,
          to: splits.last.gsub(slashes, '').strip
        }
      end.compact
    end

    def find_wiki_page(searchkey)
      # puts "KEY #{searchkey}"
      #searchkey.strip!
      searchkey.sub!(/^ /, '#') # Weird wiki-ism

      extra = /[#\?].*/
      url_extra = searchkey
                  .match(extra).to_s
                  .tr('_', '-').tr(' ', '-')
                  .downcase.squeeze('-')

      url_fixed = searchkey
                  .sub(extra, '').tr('_', ' ')
                  .gsub(/^\/|\/$/, '')
                  .downcase

      #searchkey.gsub!(extra, '')
      #
      # puts url_fixed

      match_redir = load_redirects.map do |redir|
        next if url_fixed.empty?
        if redir[:from].downcase.end_with? url_fixed.downcase
          redir[:to].downcase.tr('_', ' ')
        end
      end.compact

      result = sitemap.resources.select do |resource|
        next unless resource.data.wiki_title

        wiki_title = resource.data.wiki_title.to_s.downcase.strip

        # Check direct matches
        matches ||= wiki_title == url_fixed

        # Look for features
        #matches ||= resource.data.feature_name.to_s.tr('_', ' ').downcase == url_fixed.tr('_', ' ').downcase
        # matches ||= wiki_title == "#{url_fixed.downcase}"

        # Handle redirects
        #matches ||= match_redir.select do |redir|
          #if searchkey == '/'
            #puts "#{wiki_title} == #{redir[:to].to_s.downcase}" if wiki_title == redir[:to].to_s.downcase
          #end
          #wiki_title == redir.to_s.downcase
        #end.count > 0

        #matches ||= match_redir.include? url_fixed
        #matches ||= match_redir.include? wiki_title.scan(/[^\/]*$/)
        #matches ||= match_redir.include? "features/#{wiki_title}".downcase

        # Handle redirects
        matches ||= match_redir.include? wiki_title

        # puts "inc: " + match_redir.join(" :: ") if matches

        matches
      end.map do |resource|
        resource.url + url_extra
      end.first

      # puts "END #{result}"

      result
    end
  end
end

::Middleman::Extensions.register(:wiki_helpers, WikiHelpers)
