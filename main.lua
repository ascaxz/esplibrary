local esplib = {
    holder = {},--key = player, value = {objects = {}, step = rs connection}
    enable = false,
    teamcheck = false,
    box = false,
    healthbar = false,
    healthtext = false,
    nametag = false,
    outline = false,
    useteamcolor = false,
    limitdistance = false,
    maxdistance = 50,
    font = 3,
    nametagsize = 13,
    healthtextsize = 13,
    boxcolor = Color3.new(1, 1, 1),
    textcolor = Color3.new(1, 1, 1),
    hphigh = Color3.new(0, 1, 0),
    hplow = Color3.new(1, 0, 0)
};
local players = game:GetService("Players");
local localplayer = players.LocalPlayer;
local camera = workspace.CurrentCamera;
local runservice = game:GetService("RunService");

--common funcs
local wtvp = camera.WorldToViewportPoint;
local isa = game.IsA;
local findfirstchild = game.FindFirstChild;

local abs = math.abs;

local utils = {
    getboundingbox = function(self, character)
        local minx, miny, minz = 1 / 0, 1 / 0, 1 / 0;
        local maxx, maxy, maxz = -1 / 0, -1 / 0, -1 / 0;
        for i,v in pairs(character:GetChildren()) do
            if isa(v, "BasePart") then
                local cframe, size = v.CFrame, v.Size;
                local sx, sy, sz = size.X, size.Y, size.Z;
                local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cframe:GetComponents();
                local wsx = 0.5 * (abs(r00) * sx + abs(r01) * sy + abs(r02) * sz);
                local wsy = 0.5 * (abs(r10) * sx + abs(r11) * sy + abs(r12) * sz);
                local wsz = 0.5 * (abs(r20) * sx + abs(r21) * sy + abs(r22) * sz);

                minx = minx > x - wsx and x - wsx or minx;
                miny = miny > y - wsy and y - wsy or miny;
                minz = minz > z - wsz and z - wsz or minz;

                maxx = maxx < x + wsx and x + wsx or maxx;
                maxy = maxy < y + wsy and y + wsy or maxy;
                maxz = maxz < z + wsz and z + wsz or maxz;
            end
        end
        local omin, omax = Vector3.new(minx, miny, minz), Vector3.new(maxx, maxy, maxz);
        return (omax + omin) * 0.5, omax - omin;
    end
};

function esplib:set(type, property, value)
    for i,v in pairs(self.holder) do
        if v.objects and v.objects[type] then
            pcall(function()
                v.objects[type][property] = value;
            end);
        end
    end
end

function esplib:setstate(bool)
    self.enable = bool;
end

function esplib:getplayerteam(plr: Player)
    return plr.Team;
end

function esplib:getcharacter(plr)
    return plr.Character;
end

function esplib:gethealth(plr)
    local character = self:getcharacter(plr);
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid");
        return humanoid and {
            Health = humanoid.Health,
            MaxHealth = humanoid.MaxHealth
        };
    end
end

function esplib:isteamwithme(plr: Player)
    return (plr == localplayer
        or plr.Neutral and localplayer.Neutral
        or self:getplayerteam(plr) == self:getplayerteam(localplayer)
    );
end

function utils:createdrawing(type, prop)
    local suc, obj = pcall(Drawing.new, type);
    if not suc then return warn(obj); end
    if prop then
        for i,v in pairs(prop) do
            obj[i] = v;
        end
    end
    return obj;
end

function utils:round(num, bracket)
    bracket = bracket or 1;
    if type(num) == "number" then
        local result = math.floor(num / bracket + (math.sign(num) * 0.5)) * bracket;
        if result < 0 then
            result = result + bracket;
        end
        return result;
    end
    if typeof(num) == "Vector2" then
        return Vector2.new(self:round(num.X, bracket), self:round(num.Y, bracket));
    end
end


function esplib:addesp(plr)
    if plr == localplayer then
        return;
    end
    local ret = {objects = {}};
    ret.objects.mainbox = utils:createdrawing("Square", {
        Thickness = 2,
        Transparency = 1,
        Filled = false,
        Color = self.useteamcolor and plr.TeamColor.Color or self.boxcolor
    });
    ret.objects.boxoutline1 = utils:createdrawing("Square", {
        Thickness = 1,
        Filled = false,
        Transparency = 1
    });
    ret.objects.boxoutline2 = utils:createdrawing("Square", {
        Thickness = 1,
        Filled = false,
        Transparency = 1
    });
    ret.objects.healthbar = utils:createdrawing("Square", {
        Thickness = 2,
        Filled = true,
        Color = self.hphigh
    });
    ret.objects.healthoutline1 = utils:createdrawing("Square", {
        Thickness = 1,
        Filled = false,
        Transparency = 1
    });
    ret.objects.hptext = utils:createdrawing("Text", {
        Font = self.font,
        Size = self.healthtextsize,
        Center = true,
        Outline = self.outline,
        Color = self.useteamcolor and plr.TeamColor.Color or self.textcolor;
    });
    ret.objects.nametext = utils:createdrawing("Text", {
        Text = plr.Name,
        Font = self.font,
        Center = true,
        Outline = self.outline,
        Color = self.useteamcolor and plr.TeamColor.Color or self.textcolor;
    });
    ret.step = runservice.RenderStepped:Connect(function()
        local character = self:getcharacter(plr);
        local healthinfos = self:gethealth(plr);
        if character and healthinfos and character:FindFirstChild("HumanoidRootPart") and self.enable and (self.teamcheck and not self:isteamwithme(plr) or not self.teamcheck) then
            local hppercent = math.clamp(healthinfos.Health / healthinfos.MaxHealth, 0, 1);
            local o, size = utils:getboundingbox(character);
            local truecenter = Vector3.new(character.HumanoidRootPart.Position.X, o.Y, character.HumanoidRootPart.Position.Z);
            local height = Vector3.new(0, size.Y / 2, 0);
            local up = camera:WorldToScreenPoint(truecenter + height);
            local down = camera:WorldToScreenPoint(truecenter - height);
            local trueheight = math.abs(up.Y - down.Y);
            local pos, onscreen = camera:WorldToViewportPoint(truecenter);
            local dist = utils:round(pos.Z);
            if onscreen then
                if self.box then
                    local boxsize = utils:round(Vector2.new(trueheight / 2, trueheight));
                    local boxpos = utils:round(Vector2.new(pos.X - boxsize.X / 2, pos.Y - boxsize.Y / 2));
                    ret.objects.mainbox.Size = boxsize;
                    ret.objects.mainbox.Position = boxpos;
                    ret.objects.mainbox.Visible = true;
                else
                    ret.objects.mainbox.Visible = false;
                end

                if self.healthbar then
                    ret.objects.healthbar.Color = self.hplow:Lerp(self.hphigh, hppercent);
                    ret.objects.healthbar.Size = utils:round(Vector2.new(3, (-trueheight * hppercent)));
                    ret.objects.healthbar.Position = Vector2.new(ret.objects.mainbox.Position.X - 6, ret.objects.mainbox.Position.Y + ret.objects.mainbox.Size.Y);
                    ret.objects.healthbar.Visible = true;
                else
                    ret.objects.healthbar.Visible = false;
                end

                if self.nametag then
                    ret.objects.nametext.Position = Vector2.new(ret.objects.boxoutline1.Position.X + ret.objects.boxoutline1.Position.X / 2, ret.objects.boxoutline1.Position.Y - ret.objects.nametext.TextBounds.Y - 1);
                    ret.objects.nametext.Visible = true;
                else
                    ret.objects.nametext.Visible = false;
                end

                if self.healthtext and healthinfos.Health < 100 then
                    ret.objects.hptext.Text = tostring(math.floor(healthinfos.Health));
                    ret.objects.hptext.Position = utils:round(Vector2.new(ret.objects.healthbar.Position.X, ret.objects.healthbar.Position.Y + ret.objects.healthbar.Size.Y - ret.objects.hptext.TextBounds.Y));
                    ret.objects.hptext.Visible = true;
                else
                    ret.objects.hptext.Visible = false;
                end

                if self.outline then
                    ret.objects.nametext.Outline = true;
                    ret.objects.hptext.Outline = true;
                    ret.objects.boxoutline1.Size = Vector2.new(ret.objects.mainbox.Size.X + 2, ret.objects.mainbox.Size.Y + 2);
                    ret.objects.boxoutline1.Position = Vector2.new(ret.objects.mainbox.Position.X - 1, ret.objects.mainbox.Position.Y - 1);
                    ret.objects.boxoutline2.Size = Vector2.new(ret.objects.mainbox.Size.X - 2, ret.objects.mainbox.Size.Y - 2);
                    ret.objects.boxoutline2.Position = Vector2.new(ret.objects.mainbox.Position.X + 1, ret.objects.mainbox.Position.Y + 1);
                    ret.objects.healthoutline1.Size = Vector2.new(ret.objects.healthbar.Size.X + 2, ret.objects.boxoutline1.Size.Y);
                    ret.objects.healthoutline1.Position = Vector2.new(ret.objects.healthbar.Position.X - 1, ret.objects.boxoutline1.Position.Y);
                    ret.objects.boxoutline1.Visible = true;
                    ret.objects.boxoutline2.Visible = true;
                    ret.objects.healthoutline1.Visible = true;
                else
                    ret.objects.boxoutline1.Visible = false;
                    ret.objects.boxoutline2.Visible = false;
                    ret.objects.healthoutline1.Visible = false;
                end

                if self.limitdistance then
                    if dist > self.maxdistance then
                        for i,v in pairs(ret.objects) do
                            v.Transparency = math.clamp(self.maxdistance / dist - 0.1, 0.01, 1);
                        end
                    end
                end
            else
                for i,v in pairs(ret.objects) do
                    v.Visible = false;
                end
            end
        else
            for i,v in pairs(ret.objects) do
                v.Visible = false;
            end
        end
    end);
    self.holder[plr] = ret;
end

function esplib:removeplr(plr)
    if self.holder[plr] then
        self.holder[plr].step:Disconnect();
        for i,obj in pairs(self.holder[plr].objects) do
            obj:Remove();
        end
        self.holder[plr] = nil;
    end
end

function esplib:init()
    for i,v in pairs(players:GetPlayers()) do
        if v.Character then
            coroutine.wrap(self.addesp)(self, v);
        end
    end
    players.PlayerRemoving:Connect(function(plr)
        self:removeplr(plr);
    end);
    players.PlayerAdded:Connect(function(plr)
        self:addesp(plr);
    end);
end

return esplib
