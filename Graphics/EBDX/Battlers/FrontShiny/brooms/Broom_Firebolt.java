// Made with Blockbench 4.4.3
// Exported for Minecraft version 1.17 - 1.18 with Mojang mappings
// Paste this class into your mod and generate all required imports


public class Broom_Firebolt<T extends Entity> extends EntityModel<T> {
	// This layer location should be baked with EntityRendererProvider.Context in the entity renderer and passed into this model's constructor
	public static final ModelLayerLocation LAYER_LOCATION = new ModelLayerLocation(new ResourceLocation("modid", "broom_firebolt"), "main");
	private final ModelPart Master;

	public Broom_Firebolt(ModelPart root) {
		this.Master = root.getChild("Master");
	}

	public static LayerDefinition createBodyLayer() {
		MeshDefinition meshdefinition = new MeshDefinition();
		PartDefinition partdefinition = meshdefinition.getRoot();

		PartDefinition Master = partdefinition.addOrReplaceChild("Master", CubeListBuilder.create(), PartPose.offset(0.0F, 16.0F, 0.0F));

		PartDefinition HandleMaster = Master.addOrReplaceChild("HandleMaster", CubeListBuilder.create().texOffs(0, 21).addBox(-1.0F, -1.0F, -7.0F, 2.0F, 2.0F, 7.0F, new CubeDeformation(0.0F))
		.texOffs(17, 9).addBox(-1.0F, -4.725F, -33.9F, 2.0F, 2.0F, 21.0F, new CubeDeformation(0.0F))
		.texOffs(42, 27).addBox(-1.0F, -4.725F, -35.9F, 2.0F, 1.0F, 2.0F, new CubeDeformation(0.0F)), PartPose.offset(0.0F, 0.0F, 0.0F));

		PartDefinition cube_r1 = HandleMaster.addOrReplaceChild("cube_r1", CubeListBuilder.create().texOffs(42, 18).addBox(-1.0F, -2.0F, 2.0F, 2.0F, 2.0F, 2.0F, new CubeDeformation(0.0F))
		.texOffs(42, 22).addBox(-1.0F, -1.0F, 0.0F, 2.0F, 1.0F, 4.0F, new CubeDeformation(0.0F)), PartPose.offsetAndRotation(0.0F, -3.725F, -35.9F, -0.5236F, 0.0F, 0.0F));

		PartDefinition cube_r2 = HandleMaster.addOrReplaceChild("cube_r2", CubeListBuilder.create().texOffs(18, 20).addBox(-1.0F, -2.0F, -8.0F, 2.0F, 2.0F, 8.0F, new CubeDeformation(0.0F)), PartPose.offsetAndRotation(0.0F, 1.0F, -7.0F, -0.5236F, 0.0F, 0.0F));

		PartDefinition TwigMaster = Master.addOrReplaceChild("TwigMaster", CubeListBuilder.create().texOffs(0, 0).addBox(-1.5F, -1.5F, 0.0F, 3.0F, 3.0F, 6.0F, new CubeDeformation(0.0F))
		.texOffs(0, 9).addBox(-2.0F, -2.0F, 1.0F, 4.0F, 4.0F, 3.0F, new CubeDeformation(0.0F))
		.texOffs(0, 16).addBox(-2.0F, -2.0F, 5.0F, 4.0F, 4.0F, 1.0F, new CubeDeformation(0.0F)), PartPose.offset(0.0F, 0.0F, 0.0F));

		PartDefinition BigTwig = TwigMaster.addOrReplaceChild("BigTwig", CubeListBuilder.create(), PartPose.offset(0.0F, 0.0F, 6.0F));

		PartDefinition Twigs1 = BigTwig.addOrReplaceChild("Twigs1", CubeListBuilder.create(), PartPose.offset(0.0F, 0.0F, 0.0F));

		PartDefinition cube_r3 = Twigs1.addOrReplaceChild("cube_r3", CubeListBuilder.create().texOffs(9, 0).addBox(-4.0F, 0.0F, 0.0F, 7.0F, 0.0F, 9.0F, new CubeDeformation(0.0F)), PartPose.offsetAndRotation(1.5F, 0.5F, 0.0F, 0.1745F, 0.0F, 1.5708F));

		PartDefinition cube_r4 = Twigs1.addOrReplaceChild("cube_r4", CubeListBuilder.create().texOffs(9, 0).addBox(-4.0F, 0.0F, 0.0F, 7.0F, 0.0F, 9.0F, new CubeDeformation(0.0F)), PartPose.offsetAndRotation(-1.5F, -0.5F, 0.0F, 0.1745F, 0.0F, -1.5708F));

		PartDefinition cube_r5 = Twigs1.addOrReplaceChild("cube_r5", CubeListBuilder.create().texOffs(9, 0).addBox(-3.5F, 0.0F, 0.0F, 7.0F, 0.0F, 9.0F, new CubeDeformation(0.0F)), PartPose.offsetAndRotation(0.0F, 1.5F, 0.0F, 0.1745F, 0.0F, 3.1416F));

		PartDefinition cube_r6 = Twigs1.addOrReplaceChild("cube_r6", CubeListBuilder.create().texOffs(9, 0).addBox(-3.5F, 0.0F, 0.0F, 7.0F, 0.0F, 9.0F, new CubeDeformation(0.0F)), PartPose.offsetAndRotation(0.0F, -1.5F, 0.0F, 0.1745F, 0.0F, 0.0F));

		PartDefinition Twigs2 = BigTwig.addOrReplaceChild("Twigs2", CubeListBuilder.create(), PartPose.offsetAndRotation(0.0F, 0.0F, 0.0F, 0.0F, 0.0F, 0.7854F));

		PartDefinition cube_r7 = Twigs2.addOrReplaceChild("cube_r7", CubeListBuilder.create().texOffs(9, 0).addBox(-4.0F, 0.0F, 0.0F, 7.0F, 0.0F, 9.0F, new CubeDeformation(0.0F)), PartPose.offsetAndRotation(1.5F, 0.5F, 0.0F, 0.1745F, 0.0F, 1.5708F));

		PartDefinition cube_r8 = Twigs2.addOrReplaceChild("cube_r8", CubeListBuilder.create().texOffs(9, 0).addBox(-4.0F, 0.0F, 0.0F, 7.0F, 0.0F, 9.0F, new CubeDeformation(0.0F)), PartPose.offsetAndRotation(-1.5F, -0.5F, 0.0F, 0.1745F, 0.0F, -1.5708F));

		PartDefinition cube_r9 = Twigs2.addOrReplaceChild("cube_r9", CubeListBuilder.create().texOffs(9, 0).addBox(-3.5F, 0.0F, 0.0F, 7.0F, 0.0F, 9.0F, new CubeDeformation(0.0F)), PartPose.offsetAndRotation(0.0F, 1.5F, 0.0F, 0.1745F, 0.0F, 3.1416F));

		PartDefinition cube_r10 = Twigs2.addOrReplaceChild("cube_r10", CubeListBuilder.create().texOffs(9, 0).addBox(-3.5F, 0.0F, 0.0F, 7.0F, 0.0F, 9.0F, new CubeDeformation(0.0F)), PartPose.offsetAndRotation(0.0F, -1.5F, 0.0F, 0.1745F, 0.0F, 0.0F));

		PartDefinition LilTwig = TwigMaster.addOrReplaceChild("LilTwig", CubeListBuilder.create(), PartPose.offset(0.0F, 0.0F, 13.0F));

		PartDefinition Twigs3 = LilTwig.addOrReplaceChild("Twigs3", CubeListBuilder.create(), PartPose.offset(0.0F, 0.0F, 0.0F));

		PartDefinition cube_r11 = Twigs3.addOrReplaceChild("cube_r11", CubeListBuilder.create().texOffs(23, 0).addBox(-4.0F, 0.0F, 0.0F, 7.0F, 0.0F, 9.0F, new CubeDeformation(0.0F)), PartPose.offsetAndRotation(1.5F, 0.5F, 0.0F, 0.1745F, 0.0F, 1.5708F));

		PartDefinition cube_r12 = Twigs3.addOrReplaceChild("cube_r12", CubeListBuilder.create().texOffs(23, 0).addBox(-4.0F, 0.0F, 0.0F, 7.0F, 0.0F, 9.0F, new CubeDeformation(0.0F)), PartPose.offsetAndRotation(-1.5F, -0.5F, 0.0F, 0.1745F, 0.0F, -1.5708F));

		PartDefinition cube_r13 = Twigs3.addOrReplaceChild("cube_r13", CubeListBuilder.create().texOffs(23, 0).addBox(-3.5F, 0.0F, 0.0F, 7.0F, 0.0F, 9.0F, new CubeDeformation(0.0F)), PartPose.offsetAndRotation(0.0F, 1.5F, 0.0F, 0.1745F, 0.0F, 3.1416F));

		PartDefinition cube_r14 = Twigs3.addOrReplaceChild("cube_r14", CubeListBuilder.create().texOffs(23, 0).addBox(-3.5F, 0.0F, 0.0F, 7.0F, 0.0F, 9.0F, new CubeDeformation(0.0F)), PartPose.offsetAndRotation(0.0F, -1.5F, 0.0F, 0.1745F, 0.0F, 0.0F));

		PartDefinition Twigs4 = LilTwig.addOrReplaceChild("Twigs4", CubeListBuilder.create(), PartPose.offsetAndRotation(0.0F, 0.0F, 0.0F, 0.0F, 0.0F, 0.7854F));

		PartDefinition cube_r15 = Twigs4.addOrReplaceChild("cube_r15", CubeListBuilder.create().texOffs(23, 0).addBox(-4.0F, -0.1739F, -0.9867F, 7.0F, 0.0F, 9.0F, new CubeDeformation(0.0F)), PartPose.offsetAndRotation(1.5F, 0.5F, 1.0F, 0.1745F, 0.0F, 1.5708F));

		PartDefinition cube_r16 = Twigs4.addOrReplaceChild("cube_r16", CubeListBuilder.create().texOffs(23, 0).addBox(-4.0F, -0.1739F, -0.9867F, 7.0F, 0.0F, 9.0F, new CubeDeformation(0.0F)), PartPose.offsetAndRotation(-1.5F, -0.5F, 1.0F, 0.1745F, 0.0F, -1.5708F));

		PartDefinition cube_r17 = Twigs4.addOrReplaceChild("cube_r17", CubeListBuilder.create().texOffs(23, 0).addBox(-3.5F, -0.1739F, -0.9867F, 7.0F, 0.0F, 9.0F, new CubeDeformation(0.0F)), PartPose.offsetAndRotation(0.0F, 1.5F, 1.0F, 0.1745F, 0.0F, 3.1416F));

		PartDefinition cube_r18 = Twigs4.addOrReplaceChild("cube_r18", CubeListBuilder.create().texOffs(23, 0).addBox(-3.5F, -0.1739F, -0.9867F, 7.0F, 0.0F, 9.0F, new CubeDeformation(0.0F)), PartPose.offsetAndRotation(0.0F, -1.5F, 1.0F, 0.1745F, 0.0F, 0.0F));

		PartDefinition EndTwig = TwigMaster.addOrReplaceChild("EndTwig", CubeListBuilder.create(), PartPose.offset(0.0F, 0.0F, 17.0F));

		PartDefinition Twigs5 = EndTwig.addOrReplaceChild("Twigs5", CubeListBuilder.create(), PartPose.offset(0.0F, 0.0F, 0.0F));

		PartDefinition cube_r19 = Twigs5.addOrReplaceChild("cube_r19", CubeListBuilder.create().texOffs(37, 0).addBox(-4.0F, 0.0F, 0.0F, 7.0F, 0.0F, 9.0F, new CubeDeformation(0.0F)), PartPose.offsetAndRotation(1.5F, 0.5F, 0.0F, -0.3054F, 0.0F, 1.5708F));

		PartDefinition cube_r20 = Twigs5.addOrReplaceChild("cube_r20", CubeListBuilder.create().texOffs(37, 0).addBox(-4.0F, 0.0F, 0.0F, 7.0F, 0.0F, 9.0F, new CubeDeformation(0.0F)), PartPose.offsetAndRotation(-1.5F, -0.5F, 0.0F, -0.3054F, 0.0F, -1.5708F));

		PartDefinition cube_r21 = Twigs5.addOrReplaceChild("cube_r21", CubeListBuilder.create().texOffs(37, 0).addBox(-3.5F, 0.0F, 0.0F, 7.0F, 0.0F, 9.0F, new CubeDeformation(0.0F)), PartPose.offsetAndRotation(0.0F, 1.5F, 0.0F, -0.3054F, 0.0F, 3.1416F));

		PartDefinition cube_r22 = Twigs5.addOrReplaceChild("cube_r22", CubeListBuilder.create().texOffs(37, 0).addBox(-3.5F, 0.0F, 0.0F, 7.0F, 0.0F, 9.0F, new CubeDeformation(0.0F)), PartPose.offsetAndRotation(0.0F, -1.5F, 0.0F, -0.3054F, 0.0F, 0.0F));

		PartDefinition Twigs6 = EndTwig.addOrReplaceChild("Twigs6", CubeListBuilder.create(), PartPose.offsetAndRotation(0.0F, 0.0F, 0.0F, 0.0F, 0.0F, 0.7854F));

		PartDefinition cube_r23 = Twigs6.addOrReplaceChild("cube_r23", CubeListBuilder.create().texOffs(37, 0).addBox(-4.0F, -0.1739F, -0.9867F, 7.0F, 0.0F, 9.0F, new CubeDeformation(0.0F)), PartPose.offsetAndRotation(1.5F, 0.5F, 1.0F, -0.3054F, 0.0F, 1.5708F));

		PartDefinition cube_r24 = Twigs6.addOrReplaceChild("cube_r24", CubeListBuilder.create().texOffs(37, 0).addBox(-4.0F, -0.1739F, -0.9867F, 7.0F, 0.0F, 9.0F, new CubeDeformation(0.0F)), PartPose.offsetAndRotation(-1.5F, -0.5F, 1.0F, -0.3054F, 0.0F, -1.5708F));

		PartDefinition cube_r25 = Twigs6.addOrReplaceChild("cube_r25", CubeListBuilder.create().texOffs(37, 0).addBox(-3.5F, -0.1739F, -0.9867F, 7.0F, 0.0F, 9.0F, new CubeDeformation(0.0F)), PartPose.offsetAndRotation(0.0F, 1.5F, 1.0F, -0.3054F, 0.0F, 3.1416F));

		PartDefinition cube_r26 = Twigs6.addOrReplaceChild("cube_r26", CubeListBuilder.create().texOffs(37, 0).addBox(-3.5F, -0.1739F, -0.9867F, 7.0F, 0.0F, 9.0F, new CubeDeformation(0.0F)), PartPose.offsetAndRotation(0.0F, -1.5F, 1.0F, -0.3054F, 0.0F, 0.0F));

		return LayerDefinition.create(meshdefinition, 64, 32);
	}

	@Override
	public void setupAnim(T entity, float limbSwing, float limbSwingAmount, float ageInTicks, float netHeadYaw, float headPitch) {

	}

	@Override
	public void renderToBuffer(PoseStack poseStack, VertexConsumer vertexConsumer, int packedLight, int packedOverlay, float red, float green, float blue, float alpha) {
		Master.render(poseStack, vertexConsumer, packedLight, packedOverlay, red, green, blue, alpha);
	}
}