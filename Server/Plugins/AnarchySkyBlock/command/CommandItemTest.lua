function CommandItemTest(a_Split, a_Player)
    local item = a_Player:GetEquippedItem()
    a_Player:SendMessage("Normal: " .. ItemToString(item))
    a_Player:SendMessage("Full  : " .. ItemToFullString(item))
    return true
end
