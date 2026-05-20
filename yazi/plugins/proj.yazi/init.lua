local commands = {
	{ label = "  Новый проект",            cmd = "proj new"      },
	{ label = "  Синхронизировать footage", cmd = "proj sync"     },
	{ label = "  Статус проекта",          cmd = "proj status"   },
	{ label = "  Настройки",              cmd = "proj settings" },
	{ label = "  Шаблон папок",           cmd = "proj template" },
}

return {
	entry = function()
		local options = {}
		for _, v in ipairs(commands) do
			options[#options + 1] = v.label
		end

		local idx, event = ya.select({ title = " Studio Tools ", options = options })
		if event ~= 1 then return end

		local chosen = commands[idx]
		if chosen then
			ya.manager_emit("shell", { chosen.cmd, block = true })
		end
	end,
}
