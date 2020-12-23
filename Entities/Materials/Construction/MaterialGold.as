
void onInit(CBlob@ this)
{
  this.maxQuantity = 50;

  //this.getCurrentScript().runFlags |= Script::remove_after_this;
}

void onDie(CBlob@ blob) {
    if (isServer()) {
        if (blob.getQuantity() != 0) {
            if (!blob.hasTag("merge_killed")) {
                
                // NOTE(hobey): blob fell in the void; resummon the blob at the top of the map
                
                CMap@ map = getMap();
                
                Vec2f pos = blob.getPosition();
                
                float min_x = 16;
                float max_x = (map.tilemapwidth * map.tilesize - 16);
                if (pos.x < min_x) pos.x = min_x;
                if (pos.x > max_x) pos.x = max_x;
                
                pos.y = 0;
                bool do_summon = true;
                while (true) {
                    if (!map.isTileSolid(pos)) break;
                    pos.y += 8;
                    if (pos.y > (map.tilemapheight * map.tilesize)) {
                        do_summon = false; // NOTE(hobey): if the blob fell into the void, and there's a colomn of blocks from top to bottom of the map, delete the blob for good
                        break;
                    }
                }
                
                if (do_summon) {
                    CBlob@ new_blob = server_CreateBlobNoInit(blob.getName());
                    if (new_blob !is null) {
                        new_blob.Tag('custom quantity');
                        new_blob.Init();
                        new_blob.server_SetQuantity(blob.getQuantity());
                        new_blob.setPosition(pos);
                    }
                }
            }
        }
    }
}

