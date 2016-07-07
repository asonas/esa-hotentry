require 'esa'
require 'erb'
require 'active_support/all'

module EsaHotentry
  def self.generate_ranking
    fetcher = Fetcher.new

    rank = fetcher.posts.sort_by do |post|
      post.point
    end.reverse

    puts Template.render(rank)
  end

  class Post
    attr_accessor :point, :title, :url, :stargazers_count, :watchers_count, :comments_count

    STARGAZER_POINT = 10
    COMMENT_POINT = 5
    WATCH_POINT = 1

    def initialize(raw_post)
      @title = raw_post["title"]
      @stargazers_count = raw_post["stargazers_count"]
      @comments_count = raw_post["comments_count"]
      @watchers_count = raw_post["watchers_count"]
      @body_md = raw_post["body_md"]
      @url = raw_post["url"]
      @number = raw_post["number"]
      @title = raw_post["full_name"]
      @created_at = raw_post["created_at"]
      @point = sum_point
    end

    def summary
      delete_unneeded_lines if @title.include?("日報")
      @body_md.gsub("\r\n", "")[0..100]
    end

    # decorator
    def link
      "[#{@title}](#{@url})"
    end

    def rate
      diff = (Date.today - Date.parse(@created_at)).to_i

      case diff
      when 1
        1.2
      when 2
        1.0
      when 3
        0.9
      when 4
        0.8
      when 5
        0.5
      when 6
        0.4
      when 7
        0.3
      else
        0.1
      end
    end

    private

    def delete_unneeded_lines
      @body_md.each_line do |line|
        break if line.include?("本日の作業内容")
        @body_md.delete!(line)
      end
    end

    def sum_point
      ((stargazers_point  + comments_point + watchers_point) * rate).to_i
    end

    def stargazers_point
      @stargazers_count * STARGAZER_POINT
    end

    def comments_point
      @comments_count * COMMENT_POINT
    end

    def watchers_point
      @watchers_count * WATCH_POINT - @stargazers_count
    end
  end

  class Fetcher
    attr_accessor :posts
    def initialize
      @client = Esa::Client.new(access_token: ENV["ESA_ACCESS_TOKEN"], current_team: ENV["ESA_TEAM"])

      fetch_all_posts
    end

    def fetch_all_posts
      date = 1.week.ago.strftime("%Y-%m-%d")
      res = @client.posts(q: "created:>#{date} -in:ホッテントリ", per_page: 100)
      @posts = res.body["posts"].map { |p| Post.new(p) }

      while res.body["next_page"] != nil
        res = @client.posts(q: "created:>#{date} -in:ホッテントリ", per_page: 100, page: res.body["next_page"])
        @posts += res.body["posts"].map { |p| Post.new(p) }
      end
    end
  end

  class Template
    def self.render(ranking)
      erb = ERB.new(File.read("template.md.erb"))
      puts erb.result(binding)
    end
  end

end

EsaHotentry.generate_ranking
