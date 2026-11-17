local addonName, ns = ...
local Prices = ns.Prices

local CACHE_TTL = 60
local auctionCache = {}

local function auctionAPI()
    local api = Auctionator and Auctionator.API and Auctionator.API.v1
    if api and type(api.GetAuctionPriceByItemID) == "function" then return api end
    return nil
end

function Prices.HasAuctionSource()
    return auctionAPI() ~= nil
end

function Prices.Vendor(itemID)
    return select(11, ns.ItemInfo(itemID))
end

function Prices.Auction(itemID)
    local api = auctionAPI()
    if not api then return nil end
    local now = GetTime()
    local cached = auctionCache[itemID]
    if cached and (now - cached.at) < CACHE_TTL then return cached.value end
    local ok, value = pcall(api.GetAuctionPriceByItemID, ns.name, itemID)
    if not ok or type(value) ~= "number" or value <= 0 then value = nil end
    auctionCache[itemID] = { at = now, value = value }
    return value
end
