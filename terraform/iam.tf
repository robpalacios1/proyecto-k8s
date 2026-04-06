# 1. Create Rol

resource "aws_iam_role" "eks_cluster_role" {
    name = "api-python-eks_cluster_role"

    assume_role_policy = jsoncode({
        Version   = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = "eks.amazonaws.com"
                }
            }
        ] 
    })
}

# 2. Allow Permissions Policy

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
    role = aws_iam_role.eks_cluster_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}