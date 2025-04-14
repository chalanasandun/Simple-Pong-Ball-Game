module pong(
    input clk,
    input btn_left, btn_right,
    output vga_h_sync, vga_v_sync,
    output reg [2:0] vga_R, vga_G, vga_B
);

// === VGA Timing ===
wire inDisplayArea;
wire [9:0] CounterX;
wire [8:0] CounterY;

hvsync_generator syncgen(
    .clk(clk),
    .vga_h_sync(vga_h_sync),
    .vga_v_sync(vga_v_sync),
    .inDisplayArea(inDisplayArea),
    .hCounter(CounterX),
    .vCounter(CounterY)
);

// === Frame Parameters ===
parameter FRAME_LEFT   = 12;
parameter FRAME_RIGHT  = 636;
parameter FRAME_TOP    = 8;
parameter FRAME_BOTTOM = 472;

// === Paddle Parameters ===
parameter PADDLE_WIDTH = 112;
parameter PADDLE_HEIGHT = 8;
parameter PADDLE_Y = FRAME_BOTTOM - PADDLE_HEIGHT - 8;

// === Ball Parameters ===
parameter BALL_SIZE = 16;

// === Paddle Control ===
reg [8:0] PaddlePosition = 200;
reg btn_left_prev = 0, btn_right_prev = 0;

reg game_over = 0;
reg [1:0] miss_count = 0;  // 2-bit counter for up to 3 misses

always @(posedge clk) begin
    if (!game_over) begin
        if (btn_right && ~btn_right_prev && PaddlePosition < FRAME_RIGHT - PADDLE_WIDTH - 8)
            PaddlePosition <= PaddlePosition + 16;
        else if (btn_left && ~btn_left_prev && PaddlePosition > FRAME_LEFT + 8)
            PaddlePosition <= PaddlePosition - 16;
    end

    btn_right_prev <= btn_right;
    btn_left_prev <= btn_left;
end

// === Ball Drawing ===
reg [9:0] ballX = 100;
reg [8:0] ballY = 100;
reg ball_inX = 0, ball_inY = 0;

always @(posedge clk) begin
    if (ball_inX == 0)
        ball_inX <= (CounterX == ballX) & ball_inY;
    else
        ball_inX <= ~(CounterX == ballX + BALL_SIZE);

    if (ball_inY == 0)
        ball_inY <= (CounterY == ballY);
    else
        ball_inY <= ~(CounterY == ballY + BALL_SIZE);
end

wire ball = ball_inX & ball_inY;

// === Collision Detection ===
wire border = 
    (CounterX <= FRAME_LEFT) || (CounterX >= FRAME_RIGHT) || 
    (CounterY <= FRAME_TOP) || (CounterY >= FRAME_BOTTOM);

wire paddle = 
    (CounterX >= PaddlePosition) && 
    (CounterX <= PaddlePosition + PADDLE_WIDTH) && 
    (CounterY >= PADDLE_Y && CounterY <= PADDLE_Y + PADDLE_HEIGHT);

wire BouncingObject = border | paddle;

reg CollisionX1 = 0, CollisionX2 = 0, CollisionY1 = 0, CollisionY2 = 0;
reg UpdateBallPosition = 0;
reg ball_dirX = 0, ball_dirY = 0;

always @(posedge clk) begin
    UpdateBallPosition <= (CounterY == 500) && (CounterX == 0);

    if (UpdateBallPosition) begin
        CollisionX1 <= 0; CollisionX2 <= 0;
        CollisionY1 <= 0; CollisionY2 <= 0;
    end

    if (BouncingObject && (CounterX == ballX) && (CounterY == ballY + BALL_SIZE / 2)) CollisionX1 <= 1;
    if (BouncingObject && (CounterX == ballX + BALL_SIZE) && (CounterY == ballY + BALL_SIZE / 2)) CollisionX2 <= 1;
    if (BouncingObject && (CounterX == ballX + BALL_SIZE / 2) && (CounterY == ballY)) CollisionY1 <= 1;
    if (BouncingObject && (CounterX == ballX + BALL_SIZE / 2) && (CounterY == ballY + BALL_SIZE)) CollisionY2 <= 1;

    if (UpdateBallPosition && !game_over) begin
        if (~(CollisionX1 & CollisionX2)) begin
            ballX <= ballX + (ball_dirX ? -1 : 1);
            if (CollisionX2) ball_dirX <= 1;
            else if (CollisionX1) ball_dirX <= 0;
        end

        if (~(CollisionY1 & CollisionY2)) begin
            ballY <= ballY + (ball_dirY ? -1 : 1);
            if (CollisionY2) ball_dirY <= 1;
            else if (CollisionY1) ball_dirY <= 0;
        end

        // === Miss Detection at Bottom ===
        if ((ballY >= FRAME_BOTTOM - BALL_SIZE) && !(CollisionY1 || CollisionY2)) begin
            miss_count <= miss_count + 1;
            ballX <= 100;
            ballY <= 100;
            ball_dirY <= 0;
        end

        if (miss_count == 3)
            game_over <= 1;
    end
end

// === RGB Output ===
wire [2:0] R = {3{(BouncingObject | ball) & ~game_over}};
wire [2:0] G = {3{(BouncingObject | ball) & ~game_over}};
wire [2:0] B = {3{(BouncingObject | ball) & ~game_over}};

always @(posedge clk) begin
    vga_R <= R & {3{inDisplayArea}};
    vga_G <= G & {3{inDisplayArea}};
    vga_B <= B & {3{inDisplayArea}};
end

endmodule
