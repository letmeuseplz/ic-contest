module LBP ( clk, reset, gray_addr, gray_req, gray_ready, gray_data, lbp_addr, lbp_valid, lbp_data, finish);
input   	clk;
input   	reset;
output  [13:0] 	gray_addr;
output         	gray_req;
input   	gray_ready;
input   [7:0] 	gray_data;
output  [13:0] 	lbp_addr;
output  	lbp_valid;
output  [7:0] 	lbp_data;
output  	finish;
//
reg [13:0] gray_addr;
reg gray_req;
reg [13:0] lbp_addr;
reg lbp_valid;
reg [7:0] lbp_data;
reg finish;
//
reg [2:0] c_s,n_s;
parameter IDLE = 3'd0;
parameter READ_gc = 3'd1;
parameter COM_gp = 3'd2;
parameter RESULT = 3'd3;
parameter FINISH = 3'd4;

//
wire  [13:0] cor_lu, cor_up, cor_ru, cor_left, cor_rigt, cor_dl, cor_down, cor_dr;

//
reg [3:0] counter;
wire [3:0] weight;
//

assign weight = counter-1'd1;
//  ª¬ºA¾÷--´`§Ç
always@(posedge clk or posedge reset)
begin
    if(reset)
     c_s <= IDLE;
    else
     c_s <= n_s;
end

// output logic 
always@(*)
begin
    case(c_s)
        IDLE:
        begin
            if(gray_ready)
                n_s = READ_gc;
            else
                n_s = IDLE;
        end        
        READ_gc:
            n_s = COM_gp;            
        COM_gp:
        begin
            if(counter==4'd8)
                n_s = RESULT;
            else
                n_s = COM_gp;
        end 
        RESULT:
         begin 
            if(gcaddr==14'd16384)                 
                n_s = FINISH;
            else 
                n_s = READ_gc;
        end
        FINISH:
            n_s = FINISH;
        default:
            n_s = IDLE;
        endcase
end        
//    counter for gp because of the adjecent 8 points
always@(posedge clk or posedge reset)
begin
    if(reset)
         counter <= 4'd0;
    else if(next_state == COM_gp) 
         counter <= counter + 4'd1;
    else 
         counter <= 4'd0;
end


//finish  
always@(posedge clk or posedge reset)
begin
    if(reset) 
         finish <= 1'd0;
    else if(current_state == FINISH)
         finish <= 1'd1;
end

//lbp_valid
always@(posedge clk or posedge reset)
begin
    if(reset) 
         lbp_valid <= 1'd0;
    else if(next_state == RESULT)
         lbp_valid <= 1'd1;
    else
         lbp_valid <= 1'd0;
end

//  index x
always@(posedge clk or posedge reset)
begin
    if(reset)
        x <= 1'd1;
    else if(n_s == RESULT)
        x <= 1'd1 + x;
    else if(n_s == RESULT && x == 7'd126)
        x <= 7'd1;
end 
//  index y
always@(posedge clk or posedge reset)
begin 
    if(reset)
        y <= 1'd1;
    else if(n_s == RESULT && x == 7'd126)
        y <= 1'd1 + y;
end        
         
// gc_neighbor  

assign cor_lu = {x-1'd1,y-1'd1};
assign cor_up = {x,y-1'd1};
assign cor_ru = {x+1'd1,y-1'd1};
assign cor_left = {x-1'd1,y};
assign cor_rigt = {x+1'd1,y};
assign cor_dl = {x-1'd1,y+1'd1};
assign cor_down = {x,y+1'd1};
assign cor_dr = {x+1'd1,y+1'd1};
// gc_addr

always@(posedge clk or posedge reset)
begin
    if(reset)
        gc_addr <= {1'd1,1'd1};
    else if(next_state == READ_gc)
        gc_addr <= {x,y};
end

//   gray_address 


always@(posedge clk or posedge reset)
begin
    if(reset)
        gray_addr <= 14'd0;
    else if(n_s == READ_gc)
        gray_addr <= {x,y};
    else if(n_s == COM_gp)
    begin
        case(counter)
        4'd0: gray_addr <= cor_lu;
        4'd1: gray_addr <= cor_up;
        4'd2: gray_addr <= cor_ru;
    
        4'd3: gray_addr <= cor_left;
        4'd4: gray_addr <= cor_rigt;
        
        4'd5: gray_addr <= cor_dl;
        4'd6: gray_addr <= cor_down;
        4'd7: gray_addr <= cor_dr;
        endcase
    end
end
//  lbp address

always@(posedge clk or posedge reset)
begin
    if(reset)
        lbp_addr <= 14'd0;
    else if(n_s == RESULT) 
        lbp_addr <= gc_addr;
end

//

always@(posedge clk or posedge reset)
begin
    if(reset) 
    begin
        lbp_data <= 8'd0;
        gc_data <= 8'd0;
    end
    else if(c_s == READ_gc)
        gc_data <= gray_data;
    else if(c_s == COM_gp)
    begin
        if(gray_data>=gc_data)
              lbp_data <= lbp_data + (8'd1 << (weight));
        else
              lbp_data <= lbp_data;
    end
    else if(c_s == RESULT) 
            lbp_data <= 8'd0;
end
endmodule