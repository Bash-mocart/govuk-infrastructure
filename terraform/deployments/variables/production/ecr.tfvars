puller_arns = [
  "arn:aws:iam::172025368201:root", # Production
  "arn:aws:iam::696911096973:root", # Staging
  "arn:aws:iam::210287912431:root", # Integration
  "arn:aws:iam::430354129336:root", # Test
]

emails = [
  # TODO: manage this via a mailing list so as not to introduce toil.
  "nadeem.sabri@digital.cabinet-office.gov.uk",
  "chris.banks@digital.cabinet-office.gov.uk",
]
