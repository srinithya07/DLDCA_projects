module Encrypt(
    input [63:0]  plaintext  ,
    input [63:0]  secretKey  ,
    output [63:0] ciphertext 
);
wire [63:0] output_preordertransformation;
AddRoundKey u_addroundkey(
    .currentState(plaintext),
    .roundKey(secretKey),
    .nextState(output_preordertransformation)
);
wire [63:0] output_keyexpansion[9:0];
wire [63:0] output_round[9:0];
NextKey u_nextkey(
    .currentKey(secretKey),
    .nextKey(output_keyexpansion[0])
);
Round u_round(
    .currentState(output_preordertransformation),
    .roundKey(output_keyexpansion[0]),
    .nextState(output_round[0])
);
    genvar i;
    generate
        for(i=1;i<10;i=i+1) begin : roundkey_loop
            NextKey u_nextkey(
                .currentKey(output_keyexpansion[i-1]),
                .nextKey(output_keyexpansion[i])
            );
            Round u_round(
                .currentState(output_round[i-1]),
                .roundKey(output_keyexpansion[i]),
                .nextState(output_round[i])
            );
        end
    endgenerate
assign ciphertext = output_round[9];
endmodule

module Round(
    input  [63:0] currentState ,
    input  [63:0] roundKey,
    output [63:0] nextState    
);
wire [3:0] sbox_in[15:0];
wire [3:0] sbox_out[15:0];
wire [63:0] sbox_nextstate;
wire [63:0] shiftrows_nextstate;
    genvar i;
    generate
        for(i=0;i<16;i=i+1) begin : sbox_loop
            assign sbox_in[15-i] = currentState[63-4*i:60-4*i];
            SBox u_sbox(
                .in(sbox_in[i]),
                .out(sbox_out[i])
            );
        end
    endgenerate
assign sbox_nextstate = {sbox_out[15],sbox_out[14],sbox_out[13],sbox_out[12],sbox_out[11],sbox_out[10],sbox_out[9],sbox_out[8],sbox_out[7],sbox_out[6],sbox_out[5],sbox_out[4],sbox_out[3],sbox_out[2],sbox_out[1],sbox_out[0]};
ShiftRows u_shiftrows(
    .currentState(sbox_nextstate),
    .nextState(shiftrows_nextstate)
);
AddRoundKey u_addroundkey(
    .currentState(shiftrows_nextstate),
    .roundKey(roundKey),
    .nextState(nextState)
);
endmodule 

module SBox(
    input [3:0]in ,
    output [3:0]out
);
assign out[0]=(in[2] & (in[3] ^(~in[1]))) | ((~in[3])&(~in[2])&(~in[1])&in[0]) | ((~in[3])&in[2]&in[1]&(~in[0])) | (in[3]&(~in[2])&in[1]&(~in[0])) | (in[3]&in[2]&(~in[0])&(~in[1]));
    assign out[1] =((~in[2])&(~in[1])) | ((~in[3])&in[2]&(in[1]^in[0])) | (in[3]&(~in[2])&in[1]&(~in[0])) | (in[3]&in[2]&in[0]&(~in[1]));
    assign out[2] = ((~in[3])&(~in[2])&(in[1]^(~in[0]))) | ((~in[3])&(in[2])&(~in[0])) | (in[3]&in[1]&(~in[2])) | (in[3]&in[2]&(~in[1]));
    assign out[3] = ((~in[3])&(~in[1])&(in[0]^in[2])) | (in[2]&in[1]&(~in[3])) | (in[3]&in[2]&in[0]) | (in[3]&(~in[2])&(in[1]^(~in[0])));
endmodule

module NextKey(
    input  [63:0] currentKey,
    output [63:0] nextKey
);
    genvar i;
    generate
        for(i=0;i<15;i=i+1) begin
            assign nextKey[63-4*i:60-4*i] = currentKey[59-4*i:56-4*i];
        end
    endgenerate  
assign nextKey[3:0] = currentKey[63:60]; 
endmodule

module ShiftRows(
    input  [63:0] currentState ,
    output [63:0] nextState    
);
wire [3:0] nibble[3:0][3:0];
wire [3:0] out_nibble[3:0][3:0];
assign {nibble[0][3],nibble[0][2],nibble[0][1],nibble[0][0]} = currentState[63:48];
assign {nibble[1][3],nibble[1][2],nibble[1][1],nibble[1][0]} = currentState[47:32];
assign {nibble[2][3],nibble[2][2],nibble[2][1],nibble[2][0]} = currentState[31:16];
assign {nibble[3][3],nibble[3][2],nibble[3][1],nibble[3][0]} = currentState[15:0];
assign {out_nibble[0][3],out_nibble[0][2],out_nibble[0][1],out_nibble[0][0]} = {nibble[0][3],nibble[0][2],nibble[0][1],nibble[0][0]};
assign out_nibble[1][3] = nibble[1][2];
assign out_nibble[1][2] = nibble[1][1];
assign out_nibble[1][1] = nibble[1][0];
assign out_nibble[1][0] = nibble[1][3];
assign out_nibble[2][3] = nibble[2][1];
assign out_nibble[2][2] = nibble[2][0];
assign out_nibble[2][1] = nibble[2][3];
assign out_nibble[2][0] = nibble[2][2];
assign out_nibble[3][3] = nibble[3][0];
assign out_nibble[3][2] = nibble[3][3];
assign out_nibble[3][1] = nibble[3][2];
assign out_nibble[3][0] = nibble[3][1];
assign nextState[63:48] = {out_nibble[0][3], out_nibble[0][2],out_nibble[0][1],out_nibble[0][0]};
assign nextState[47:32] = {out_nibble[1][3], out_nibble[1][2],out_nibble[1][1],out_nibble[1][0]};
assign nextState[31:16] = {out_nibble[2][3], out_nibble[2][2],out_nibble[2][1],out_nibble[2][0]};
assign nextState[15:0] = {out_nibble[3][3], out_nibble[3][2],out_nibble[3][1],out_nibble[3][0]};
endmodule

module AddRoundKey(
    input  [63:0] currentState ,
    input  [63:0] roundKey     ,
    output [63:0] nextState    
);
assign nextState = currentState^roundKey;
endmodule 
