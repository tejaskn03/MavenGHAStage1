data "aws_elastic_beanstalk_solution_stack" "java21" {
  most_recent = true
  name_regex  = "^64bit Amazon Linux 2023 .* running Corretto 21$"
}

# IAM assume-role policy for EC2
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# IAM role for EC2 instances
resource "aws_iam_role" "ec2_role" {
  name               = "${var.application_name}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

# Attach Elastic Beanstalk Web Tier policy to EC2 role
resource "aws_iam_role_policy_attachment" "ec2_role_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

# Instance profile for EC2
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.application_name}-ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# IAM assume-role policy for Elastic Beanstalk
data "aws_iam_policy_document" "eb_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["elasticbeanstalk.amazonaws.com"]
    }
  }
}

# IAM role for Elastic Beanstalk
resource "aws_iam_role" "eb_role" {
  name               = "${var.application_name}-eb-role"
  assume_role_policy = data.aws_iam_policy_document.eb_assume_role.json
}

# Elastic Beanstalk Enhanced Health policy
resource "aws_iam_role_policy_attachment" "eb_role_policy_attachment" {
  role       = aws_iam_role.eb_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkEnhancedHealth"
}

# Elastic Beanstalk Managed Updates policy
resource "aws_iam_role_policy_attachment" "eb_role_policy_attachment2" {
  role       = aws_iam_role.eb_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkManagedUpdatesCustomerRolePolicy"
}

# Elastic Beanstalk application
resource "aws_elastic_beanstalk_application" "streamflix" {
  name        = var.application_name
  description = "Elastic Beanstalk Application for ${var.application_name}"
}

# Elastic Beanstalk environment
resource "aws_elastic_beanstalk_environment" "streamflix_env" {
  name                = var.environment_name
  application         = aws_elastic_beanstalk_application.streamflix.name
  solution_stack_name = data.aws_elastic_beanstalk_solution_stack.java21.name

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "SingleInstance"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = aws_iam_role.eb_role.arn
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.ec2_instance_profile.name
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = var.instance_type
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "PORT"
    value     = "8080"
  }
}

# Elastic Beanstalk environment URL
output "elastic_beanstalk_environment_url" {
  value = aws_elastic_beanstalk_environment.streamflix_env.endpoint_url
}

# Elastic Beanstalk environment name
output "elastic_beanstalk_environment_name" {
  value = aws_elastic_beanstalk_environment.streamflix_env.name
}

