# Built-in starter packs that hosts can apply to a new game.
# Pure Ruby (no DB) so templates ship with the app.
class GameTemplate
  attr_reader :slug, :title, :description, :categories, :missions

  def initialize(slug:, title:, description:, categories:, missions:)
    @slug = slug
    @title = title
    @description = description
    @categories = categories
    @missions = missions
  end

  def self.all
    @all ||= [
      new(
        slug: "birthday",
        title: "Birthday Party",
        description: "Indoor + outdoor missions for a birthday celebration.",
        categories: [
          { name: "Cake & Sweets",  color: "#F472B6" },
          { name: "Group Moments",  color: "#A78BFA" },
          { name: "Mischief",       color: "#FB923C" }
        ],
        missions: [
          { category: "Cake & Sweets", title: "Candles being blown out",      points: 200 },
          { category: "Cake & Sweets", title: "Cake on someone's face",       points: 250, repeatable: true, max_submissions_per_team: 3 },
          { category: "Group Moments", title: "Full group selfie",            points: 300, required: true },
          { category: "Group Moments", title: "Three generations in frame",   points: 250 },
          { category: "Mischief",      title: "Best gift wrapped worst",      points: 150 },
          { category: "Mischief",      title: "Surprise dance move",          points: 200 }
        ]
      ),
      new(
        slug: "bachelor",
        title: "Bachelor / Bachelorette Weekend",
        description: "Light-touch challenges around town.",
        categories: [
          { name: "Drinks",  color: "#F59E0B" },
          { name: "Photo Ops", color: "#22C55E" },
          { name: "Bold Asks", color: "#EF4444" }
        ],
        missions: [
          { category: "Drinks",     title: "Toast with someone you just met", points: 200 },
          { category: "Drinks",     title: "Sample a cocktail off the menu",  points: 100, repeatable: true, max_submissions_per_team: 5 },
          { category: "Photo Ops",  title: "Pose with a local statue",         points: 150 },
          { category: "Photo Ops",  title: "Sunset over a skyline",            points: 250 },
          { category: "Bold Asks",  title: "Get a stranger to compliment the guest of honor", points: 300 },
          { category: "Bold Asks",  title: "Sing a song with a karaoke crowd", points: 400, first_bonus_count: 1, first_bonus_points: 100 }
        ]
      ),
      new(
        slug: "office",
        title: "Office Offsite",
        description: "Team-bonding missions for an offsite.",
        categories: [
          { name: "Team",     color: "#3B82F6" },
          { name: "Learning", color: "#10B981" },
          { name: "Fun",      color: "#F472B6" }
        ],
        missions: [
          { category: "Team",     title: "Team logo on a sign",      points: 200 },
          { category: "Team",     title: "Whole team jumping shot",  points: 300, required: true },
          { category: "Learning", title: "Quote from today's session", points: 150 },
          { category: "Learning", title: "Sketch of one big idea",   points: 200 },
          { category: "Fun",      title: "Goofiest expression",      points: 100, repeatable: true, max_submissions_per_team: 3 },
          { category: "Fun",      title: "Sunset hangout shot",      points: 250 }
        ]
      ),
      new(
        slug: "family",
        title: "Family Reunion",
        description: "All-ages, low-pressure missions.",
        categories: [
          { name: "People",  color: "#A78BFA" },
          { name: "Places",  color: "#22C55E" },
          { name: "History", color: "#F59E0B" }
        ],
        missions: [
          { category: "People",  title: "Three cousins in one photo",    points: 200 },
          { category: "People",  title: "The oldest + youngest person",  points: 250 },
          { category: "Places",  title: "Photo at the family meeting spot", points: 150 },
          { category: "Places",  title: "Group hike or walk shot",       points: 200 },
          { category: "History", title: "Pose with an old family photo", points: 200 },
          { category: "History", title: "Recreate a childhood photo",    points: 350, first_bonus_count: 1, first_bonus_points: 150 }
        ]
      )
    ]
  end

  def self.find(slug)
    all.find { |t| t.slug == slug }
  end

  # Apply this template to a game (additive — does not clear existing).
  def apply_to!(game)
    Mission.transaction do
      cat_lookup = {}
      categories.each_with_index do |c, idx|
        cat = game.mission_categories.create!(
          name: c[:name],
          color: c[:color] || "#10B981",
          position: game.mission_categories.count + idx
        )
        cat_lookup[c[:name]] = cat
      end
      missions.each_with_index do |m, idx|
        game.missions.create!(
          mission_category: cat_lookup[m[:category]],
          title: m[:title],
          description: m[:description],
          points: m[:points] || 100,
          bonus_points: m[:bonus_points] || 0,
          first_bonus_count: m[:first_bonus_count] || 0,
          first_bonus_points: m[:first_bonus_points] || 0,
          mission_type: m[:mission_type] || "photo",
          position: game.missions.count + idx,
          required: m[:required] || false,
          repeatable: m[:repeatable] || false,
          max_submissions_per_team: m[:max_submissions_per_team] || 1,
          requires_location: m[:requires_location] || false
        )
      end
    end
    game
  end
end
