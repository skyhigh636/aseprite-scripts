
    local spr = app.sprite or Sprite(img.width, img.height)
    local cel = spr:newCel(app.layer, app.frame, img, Point(0, 0))

    local dlg = Dialog("Import Image")

    dlg:file{
    id = "imagePath",
    label = "Image:",
    title = "Choose an image",
    open = true,
        filetypes = { "png", "jpg", "jpeg", "gif", "bmp", "ase", "aseprite" }
    }
    dlg:button{ id = "ok", text = "Import" }
    dlg:button{ id = "cancel", text = "Cancel" }
    dlg:show()

    local data = dlg.data
    if not data.ok then return end

    local path = data.imagePath
    if not path or path == "" then
    app.alert("No file selected.")
    return
    end

    local img = Image{ fromFile = path }

    -- Use the active sprite, or make a new one sized to the image
    local spr = app.sprite or Sprite(img.width, img.height)

    app.transaction(function()
    spr:newCel(app.layer, app.frame, img, Point(0, 0))
    end)

    app.refresh()