
#ifdef STAGING
// CParticle wrappers, use them when you want to store CParticles@
// Basic particle wrapper
class Particle {
    CParticle@ particle = null;

    Particle(CParticle@ &in p) {
        @particle = p;

        p.AddDeathCallback(@onParticleDeath);
        p.EnableCustomData();
        p.customData.store(@this);
    }
}

void onParticleDeath(CParticle@ me) {
    Particle@ p;
    me.customData.retrieve(@p);
    
    @p.particle = null;
}

class ParticleLight : Particle {
    CParticle@ light = null;

    ParticleLight(CParticle@ &in p, SColor &in color = SColor(255, 255, 255, 255), float fadeoutmod = 0.97f) {
        super(p);

        if (p !is null)
            setupLight(color, fadeoutmod);
    }

    void setupLight(SColor &in color, float fadeoutmod = 0.97f) {
        @light = ParticleAnimated(
            "light.png",
            particle.position,
            particle.velocity,
            0.0f,
            0.3f,
            0,
            0,
            Vec2f(256, 256),
            0,
            0.0f,
            false
        );

        if (light !is null)
        {
            light.timeout = particle.timeout;
            light.deadeffect = particle.deadeffect;
            light.diesonanimate = false;
            light.colour = color;
            light.fadeout = true;
            light.fadeoutmod = fadeoutmod;
            light.setRenderStyle(RenderStyle::light, false, true);

            light.AddDeathCallback(@onLightDeath);
            light.EnableCustomData();
            light.customData.store(@this);
        }
    }

    void updateLight() {
        if (particle is null || light is null)
            return;

        light.position = particle.position;
        light.velocity = particle.velocity;
    }
}

void onLightDeath(CParticle@ me) {
    ParticleLight@ p;
    me.customData.retrieve(@p);
    
    @p.light = null;
}

CParticle@ MakeBasicLightParticle(Vec2f position, Vec2f velocity, SColor colour, float fadeoutmod, float scale, int timeout) {
    CParticle@ p = ParticleAnimated(
            "light.png",
            position,
            velocity,
            0.0f,
            0.3f,
            0,
            0,
            Vec2f(256, 256),
            0,
            0.0f,
            false
        );

    if (p is null)
        return null;

    p.timeout = timeout;
    p.deadeffect = -1;
    p.diesonanimate = false;
    p.colour = colour;
    p.fadeout = true;
    p.fadeoutmod = fadeoutmod;
    p.scale = scale;
    p.setRenderStyle(RenderStyle::light, false, true);

    return @p;
}

CParticle@ MakeExplosionLightParticle(Vec2f position, Vec2f extra_velocity_impulse = Vec2f_zero)
{
    Random r(XORRandom(9999));

    CParticle@ p = ParticleAnimated(
        "light.png",
        position,
        getRandomVelocity(0, r.NextFloat() * 1.0f, 360.0f) + extra_velocity_impulse,
        0.0f,
        0.3f + r.NextFloat() * 0.1f,
        0,
        0,
        Vec2f(256, 256),
        0,
        0.0f,
        false);

    if (p is null) { return null; }

    p.timeout = 30;
    p.deadeffect = -1;
    p.diesonanimate = false;
    p.colour = SColor(255, 255, 170, 0);
    p.fadeout = true;
    p.fadeoutmod = 0.85f + r.NextFloat() * 0.075f;
    p.setRenderStyle(RenderStyle::light, false, true);

    return @p;
}

#endif