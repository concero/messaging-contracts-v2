export const isDeployToStage = () => {
	return process.env.DEPLOY_TO_STAGE === "true";
};
