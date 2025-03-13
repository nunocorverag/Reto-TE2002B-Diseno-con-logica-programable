
// Módulo para dibujar una carita feliz
module smiley_face(
    input [9:0] x,
    input [9:0] y,
    output pixel_on
);
    // Definir la posición y tamaño de la carita feliz
    parameter FACE_X = 320;      // Centro X
    parameter FACE_Y = 240;      // Centro Y
    parameter FACE_RADIUS = 100; // Radio de la cara
    parameter EYE_RADIUS = 15;   // Radio de los ojos
    parameter EYE_X_OFFSET = 40; // Distancia de los ojos al centro
    parameter EYE_Y_OFFSET = 30; // Distancia de los ojos al centro
    parameter SMILE_RADIUS = 60; // Radio de la sonrisa
    parameter SMILE_Y_OFFSET = 20; // Distancia de la sonrisa al centro

    // Calcular distancias cuadradas (más eficiente que usar raíz cuadrada)
    wire [19:0] face_dist_sq = (x - FACE_X) * (x - FACE_X) + (y - FACE_Y) * (y - FACE_Y);
    wire [19:0] left_eye_dist_sq = (x - (FACE_X - EYE_X_OFFSET)) * (x - (FACE_X - EYE_X_OFFSET)) + 
                                  (y - (FACE_Y - EYE_Y_OFFSET)) * (y - (FACE_Y - EYE_Y_OFFSET));
    wire [19:0] right_eye_dist_sq = (x - (FACE_X + EYE_X_OFFSET)) * (x - (FACE_X + EYE_X_OFFSET)) + 
                                   (y - (FACE_Y - EYE_Y_OFFSET)) * (y - (FACE_Y - EYE_Y_OFFSET));
    
    // Para la sonrisa (semicírculo)
    wire [19:0] smile_dist_sq = (x - FACE_X) * (x - FACE_X) + (y - (FACE_Y + SMILE_Y_OFFSET)) * (y - (FACE_Y + SMILE_Y_OFFSET));
    
    
    // Dibujar los ojos (círculos sólidos)
    wire left_eye = (left_eye_dist_sq <= EYE_RADIUS * EYE_RADIUS);
    wire right_eye = (right_eye_dist_sq <= EYE_RADIUS * EYE_RADIUS);
    
    // Dibujar la sonrisa (semiarco)
    wire smile = (smile_dist_sq <= SMILE_RADIUS * SMILE_RADIUS) && 
                (smile_dist_sq >= (SMILE_RADIUS-5) * (SMILE_RADIUS-5)) &&
                (y > FACE_Y + SMILE_Y_OFFSET);
    
    // Combinar todos los elementos
    assign pixel_on = left_eye || right_eye || smile;
    
endmodule

