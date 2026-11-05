-- The wording below was supplied by the player. Edit here to change the curriculum.
-- Keep each section short enough to type comfortably in the game's single-line box.
CovenantVerses = {
  {
    id = "revelation_3_17_18", reference = "Revelation 3:17-18",
    cue = "Gold, white clothes, and sight", translation = "NIV",
    sections = {
      "You say, 'I am rich; I have acquired wealth and do not need a thing.'",
      "But you do not realize that you are wretched, pitiful, poor, blind and naked.",
      "I counsel you to buy from me gold refined in the fire, so you can become rich;",
      "and white clothes to wear, so you can cover your shameful nakedness;",
      "and salve to put on your eyes, so you can see."
    }
  },
  {
    id = "hebrews_9_8", reference = "Hebrews 9:8",
    cue = "The way into the Most Holy Place", translation = "NIV",
    sections = {
      "The Holy Spirit was showing by this that the way into the Most Holy Place",
      "had not yet been disclosed as long as the first tabernacle was still functioning."
    }
  },
  {
    id = "malachi_3_1", reference = "Malachi 3:1",
    cue = "The messenger of the covenant", translation = "NIV",
    sections = {
      "\"I will send my messenger, who will prepare the way before me.",
      "Then suddenly the Lord you are seeking will come to his temple;",
      "the messenger of the covenant, whom you desire, will come,\" says the LORD Almighty."
    }
  },
  {
    id = "hebrews_8_5", reference = "Hebrews 8:5",
    cue = "The copy, the shadow, and the mountain pattern", translation = "NIV",
    sections = {
      "They serve at a sanctuary that is a copy and shadow of what is in heaven.",
      "This is why Moses was warned when he was about to build the tabernacle:",
      "\"See to it that you make everything according to the pattern shown you on the mountain.\""
    }
  },
  {
    id = "john_14_29", reference = "John 14:29",
    cue = "Told beforehand, so that you will believe", translation = "NIV",
    sections = {
      "I have told you now before it happens,",
      "so that when it does happen you will believe."
    }
  }
}

for _, verse in ipairs(CovenantVerses) do
  verse.text = table.concat(verse.sections, " ")
end
