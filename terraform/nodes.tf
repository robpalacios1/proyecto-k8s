resource "aws_eks_node_group" "main_nodes" {
    cluster_name    = aws_eks_cluster.main_cluster.name
    node_group_name = "api-python-node-node-group"
    node_role_arn   = aws_iam_role.eks_node_role.arn

    #subnets
    subnet_ids = [
        aws_subnet.public_subnet_1.id,
        aws_subnet.public_subnet_2.id
    ]

    #server
    scaling_config {
        desired_size = 2
        max_size     = 3
        min_size     = 1
    }

    # Kind of instances (2 vCPU, 1GB RAM)
    instance_types = ["t3.micro"]

    depends_on  = [
        aws_iam_role_policy_attachment.eks_node_policy,
        aws_iam_role_policy_attachment.eks_cni_policy,
        aws_iam_role_policy_attachment.eks_registry_policy
    ]
}