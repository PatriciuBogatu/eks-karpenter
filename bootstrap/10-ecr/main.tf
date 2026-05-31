resource "aws_ecr_repository" "this" {
  for_each = toset(var.services)

  name = "${var.project}/${each.key}"

  # MUTABLE so you can re-push :latest while iterating in a learning project.
  # In real prod you'd often set IMMUTABLE and deploy by immutable digest/SHA tag
  # — worth mentioning in an interview as the safer default.
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true # free basic CVE scan on every push
  }
}

# Cost + hygiene: drop untagged layers quickly and cap tagged image history.
resource "aws_ecr_lifecycle_policy" "this" {
  for_each   = aws_ecr_repository.this
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep only the last 10 tagged images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = { type = "expire" }
      }
    ]
  })
}
