local d = getDisplays()[1]
d.reset()
d.clear()
d.forceFlush()

local width, height = d.getWidth(), d.getHeight()
local borderOffset = 8

local function generateSpeed()
    return math.random(50, 300) / 100
end

local function generateColor()
    return sm.color.new(math.random(), math.random(), math.random())
end

local balls = {}
for i = 1, 32 do
    table.insert(balls, {
        x = math.random(borderOffset, width - 1 - borderOffset),
        y = math.random(borderOffset, height - 1 - borderOffset),
        vx = math.random() - 0.5,
        vy = math.random() - 0.5,
        speed = generateSpeed(),
        color = generateColor()
    })
end

function callback_loop()
	if _endtick then
		d.clear()
		d.forceFlush()
		return
	end

	d.clear()
    local mul = getSkippedTicks() + 1
	for i, ball in ipairs(balls) do
        ball.x = ball.x + ball.vx * ball.speed * mul
        ball.y = ball.y + ball.vy * ball.speed * mul
        if (ball.x < 0 or ball.x >= width) and not ball.colideX then
            ball.colideX = true
            ball.vx = -ball.vx
            ball.speed = generateSpeed()
            ball.color = generateColor()
        else
            ball.colideX = false
        end
        if (ball.y < 0 or ball.y >= height) and not ball.colideY then
            ball.colideY = true
            ball.vy = -ball.vy
            ball.speed = generateSpeed()
            ball.color = generateColor()
        else
            ball.colideY = false
        end
        d.fillCircle(ball.x, ball.y, 5, ball.color)
    end
	d.flush()
end