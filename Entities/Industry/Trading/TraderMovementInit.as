// Runner Movement

#include "RunnerCommon.as"

void onInit( CMovement@ this )
{
    RunnerMoveVars moveVars;
    //walking vars
    moveVars.walkSpeed = 0.5f;
    moveVars.walkSpeedInAir = 0.3f;
    moveVars.walkFactor = 1.0f;
    moveVars.walkLadderSpeed.Set( 0.15f, 0.6f );
    //jumping vars
    moveVars.jumpMaxVel = 2.9f;
    moveVars.jumpStart = 1.0f;
    moveVars.jumpMid = 0.55f;
    moveVars.jumpEnd = 0.4f;
    moveVars.jumpFactor = 1.0f;
    moveVars.jumpCount = 0;
    moveVars.canVault = false;
    //swimming
    moveVars.swimspeed = 0.3;
    moveVars.swimforce = 30;
    moveVars.swimEdgeScale = 1.2f;
    //the overall scale of movement
    moveVars.overallScale = 1.0f;
    //stopping forces
    moveVars.stoppingForce = 0.3f; //function of mass
    moveVars.stoppingForceAir = 0.10f; //function of mass
    this.getBlob().set( "moveVars", moveVars );
    this.getBlob().getShape().getVars().waterDragScale = 30.0f;
	this.getBlob().getShape().getConsts().collideWhenAttached = true;
}
