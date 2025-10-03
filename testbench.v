`timescale 1ns/1ps

module Encrypt_tb;
    reg [63:0] plaintext;
    reg [63:0] secretKey;
    wire [63:0] ciphertext;

    Encrypt uut (
        .plaintext(plaintext),
        .secretKey(secretKey),
        .ciphertext(ciphertext)
    );

    initial begin
        $display("Time\t\tPlaintext\t\tSecretKey\t\tCiphertext");
        $monitor("%0t\t%h\t%h\t%h", $time, plaintext, secretKey, ciphertext);

        plaintext = 64'h0123456789ABCDEF;
        secretKey = 64'h0F1E2D3C4B5A6978; // expected cipher text: 895041ff237ae3c8

        #10;

        plaintext = 64'h1111222233334444; // expected cipher text: 68ad60e74a7ee30c
        secretKey = 64'hAABBCCDDEEFF0011;

        #10;

        $finish;
    end

endmodule

