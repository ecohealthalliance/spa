Feeds = new Meteor.Collection(null)
[
  _id: "1"
  tags: ["AH", "EDR"]
  label: "English"
  checked: true
,
  _id: "7"
  tags: ["ESP"]
  label: "Español (Spanish)"
,
  _id: "12"
  tags: ["RUS"]
  label: "Русский (Russian)"
,
  _id: "15"
  tags: ["MBDS"]
  label: "Mekong Basin"
,
  _id: "18"
  tags: ["FRA"]
  label: "Afrique Francophone"
,
  _id: "24"
  tags: ["EAFR"]
  label: "Anglophone Africa"
,
  _id: "26"
  tags: ["PORT"]
  label: "Português"
,
  _id: "170"
  tags: ["SOAS"]
  label: "South Asia"
,
  _id: "171"
  tags: ["MENA"]
  label: "Middle East/North Africa"
].forEach((feed)=>Feeds.insert(feed))
module.exports = Feeds
